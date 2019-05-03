defmodule SegmentChallenge.Projections.ActivityFeedProjector do
  use Commanded.Projections.Ecto, name: "ActivityFeedProjection"

  use SegmentChallenge.Stages.Stage.Aliases

  require Logger

  import SegmentChallenge.Challenges.Formatters.TimeFormatter,
    only: [duration: 1, elapsed_time: 1]

  import SegmentChallenge.Challenges.Formatters.DistanceFormatter, only: [distance: 1]

  alias SegmentChallenge.Events.AthleteAccumulatedActivityInChallengeLeaderboard
  alias SegmentChallenge.Events.AthleteAccumulatedPointsInChallengeLeaderboard
  alias SegmentChallenge.Events.AthleteAchievedChallengeGoal
  alias SegmentChallenge.Events.AthleteAchievedStageGoal
  alias SegmentChallenge.Events.AthleteImported
  alias SegmentChallenge.Events.AthleteProfileChanged
  alias SegmentChallenge.Events.AthleteRankedInStageLeaderboard
  alias SegmentChallenge.Events.AthleteRecordedImprovedStageEffort
  alias SegmentChallenge.Events.ClubImported
  alias SegmentChallenge.Events.ClubProfileChanged
  alias SegmentChallenge.Events.ChallengeApproved
  alias SegmentChallenge.Events.ChallengeCancelled
  alias SegmentChallenge.Events.ChallengeCreated
  alias SegmentChallenge.Events.ChallengeEnded
  alias SegmentChallenge.Events.ChallengeLeaderboardCreated
  alias SegmentChallenge.Events.ChallengeStarted
  alias SegmentChallenge.Events.ChallengeLeaderboardsApproved
  alias SegmentChallenge.Events.ChallengeLeaderboardFinalised
  alias SegmentChallenge.Events.ChallengeLeaderboardRanked
  alias SegmentChallenge.Events.CompetitorExcludedFromChallenge
  alias SegmentChallenge.Events.CompetitorLeftChallenge
  alias SegmentChallenge.Events.CompetitorJoinedChallenge
  alias SegmentChallenge.Events.CompetitorRemovedFromStage
  alias SegmentChallenge.Events.CompetitorsJoinedChallenge
  alias SegmentChallenge.Events.StageLeaderboardCreated
  alias SegmentChallenge.Events.StageLeaderboardCleared
  alias SegmentChallenge.Events.StageLeaderboardRanked
  alias SegmentChallenge.Events.StageLeaderboardFinalised
  alias SegmentChallenge.Events.StageLeaderboardsApproved
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActorProjection
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection
  alias SegmentChallenge.Repo

  @athlete "athlete"
  @challenge "challenge"
  @challenge_leaderboard "challenge_leaderboard"
  @club "club"
  @stage "stage"
  @stage_leaderboard "stage_leaderboard"

  project %AthleteImported{athlete_uuid: athlete_uuid, fullname: name, profile: profile},
          fn multi ->
            record_actor(multi, @athlete, athlete_uuid, name, profile)
          end

  project %AthleteProfileChanged{athlete_uuid: athlete_uuid, profile: profile}, fn multi ->
    multi
    |> update_actor_image(@athlete, athlete_uuid, profile)
    |> update_activity_images(@athlete, athlete_uuid, profile)
  end

  project %ClubImported{club_uuid: club_uuid, name: name, profile: profile}, fn multi ->
    record_actor(multi, @club, club_uuid, name, profile)
  end

  project %ClubProfileChanged{club_uuid: club_uuid, profile: profile}, fn multi ->
    multi
    |> update_actor_image(@club, club_uuid, profile)
    |> update_activity_images(@club, club_uuid, profile)
  end

  project %ChallengeCreated{} = event, %{created_at: timestamp}, fn multi ->
    %ChallengeCreated{
      challenge_uuid: challenge_uuid,
      name: name,
      hosted_by_club_uuid: hosted_by_club_uuid
    } = event

    multi
    |> Ecto.Multi.insert(:challenge_object, %ActorProjection{
      actor_uuid: challenge_uuid,
      actor_type: @challenge,
      actor_name: name
    })
    |> Ecto.Multi.run(:created_activity_actor, fn _repo, _changes ->
      get_actor(hosted_by_club_uuid)
    end)
    |> Ecto.Multi.run(:activity_feed_activity, fn repo, changes ->
      %{created_activity_actor: actor, challenge_object: object} = changes

      params = %{
        published: timestamp,
        actor: actor,
        verb: "create",
        object: object,
        target: nil,
        message: "Created challenge #{name}"
      }

      case create_activity_projection(params) do
        {:ok, activity} -> repo.insert(activity)
        {:error, :invalid_activity} -> {:ok, nil}
      end
    end)
  end

  project %ChallengeCancelled{challenge_uuid: challenge_uuid}, fn multi ->
    delete_actor(multi, @challenge, challenge_uuid)
  end

  @doc """
  Include competitors "joined" challenge when approved.
  """
  project %ChallengeApproved{} = event,
          %{created_at: timestamp, stream_version: stream_version},
          fn multi ->
            %ChallengeApproved{challenge_uuid: challenge_uuid} = event

            Ecto.Multi.run(multi, :feed_activity, fn _repo, _changes ->
              competitors = challenge_competitors(challenge_uuid, stream_version)

              for athlete_uuid <- competitors do
                do_insert_activity_projection(
                  published: timestamp,
                  verb: "join",
                  actor_uuid: athlete_uuid,
                  object_uuid: challenge_uuid,
                  message: fn _actor, object -> "Joined challenge #{object}" end
                )
              end

              {:ok, nil}
            end)
          end

  project %CompetitorJoinedChallenge{} = event,
          %{created_at: timestamp, stream_version: stream_version},
          fn multi ->
            %CompetitorJoinedChallenge{challenge_uuid: challenge_uuid, athlete_uuid: athlete_uuid} =
              event

            if challenge_approved?(challenge_uuid, stream_version) do
              insert_activity_projection(
                multi,
                timestamp,
                "join",
                athlete_uuid,
                challenge_uuid,
                fn _actor, object -> "Joined challenge #{object}" end
              )
            else
              multi
            end
          end

  project %CompetitorsJoinedChallenge{} = event,
          %{
            created_at: timestamp,
            stream_version: stream_version
          },
          fn multi ->
            %CompetitorsJoinedChallenge{challenge_uuid: challenge_uuid, competitors: competitors} =
              event

            if challenge_approved?(challenge_uuid, stream_version) do
              competitors
              |> Enum.uniq_by(fn competitor -> competitor.athlete_uuid end)
              |> Enum.reduce(multi, fn competitor, multi ->
                insert_activity_projection(
                  multi,
                  timestamp,
                  "join",
                  competitor.athlete_uuid,
                  challenge_uuid,
                  fn _actor, object -> "Joined challenge #{object}" end
                )
              end)
            else
              multi
            end
          end

  project %CompetitorLeftChallenge{} = event, fn multi ->
    %CompetitorLeftChallenge{challenge_uuid: challenge_uuid, athlete_uuid: athlete_uuid} = event

    Ecto.Multi.delete_all(
      multi,
      :delete_athlete_activity,
      actor_object_activity_query(athlete_uuid, challenge_uuid),
      []
    )
  end

  project %CompetitorRemovedFromStage{} = event, fn multi ->
    %CompetitorRemovedFromStage{stage_uuid: stage_uuid, athlete_uuid: athlete_uuid} = event

    Ecto.Multi.delete_all(
      multi,
      :delete_athlete_activity,
      actor_object_activity_query(athlete_uuid, stage_uuid),
      []
    )
  end

  project %CompetitorExcludedFromChallenge{} = event, fn multi ->
    %CompetitorExcludedFromChallenge{
      challenge_uuid: challenge_uuid,
      athlete_uuid: athlete_uuid
    } = event

    Ecto.Multi.delete_all(
      multi,
      :delete_athlete_activity,
      actor_object_activity_query("join", athlete_uuid, challenge_uuid),
      []
    )
  end

  project %StageCreated{} = event, fn multi ->
    %StageCreated{stage_uuid: stage_uuid, name: name} = event

    record_actor(multi, @stage, stage_uuid, name)
  end

  project %StageDeleted{} = event, fn multi ->
    %StageDeleted{stage_uuid: stage_uuid} = event

    delete_actor(multi, @stage, stage_uuid)
  end

  project %ChallengeLeaderboardCreated{} = event, fn multi ->
    %ChallengeLeaderboardCreated{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      name: name
    } = event

    record_actor(multi, @challenge_leaderboard, challenge_leaderboard_uuid, name)
  end

  project %StageLeaderboardCreated{stage_leaderboard_uuid: stage_leaderboard_uuid, name: name},
          fn multi ->
            record_actor(multi, @stage_leaderboard, stage_leaderboard_uuid, name)
          end

  project %ChallengeStarted{challenge_uuid: challenge_uuid, start_date_local: start_date_local},
          fn multi ->
            insert_activity_projection(
              multi,
              published: start_date_local,
              verb: "start",
              actor_uuid: challenge_uuid,
              object_uuid: challenge_uuid,
              message: fn _actor, object -> "Challenge #{object} started" end
            )
          end

  project %StageStarted{} = event, fn multi ->
    %StageStarted{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      start_date_local: start_date_local
    } = event

    insert_activity_projection(
      multi,
      start_date_local,
      "start",
      challenge_uuid,
      stage_uuid,
      fn _actor, object -> "Stage #{object} started" end
    )
  end

  project %StageEffortRecorded{} = event, fn multi ->
    %StageEffortRecorded{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      start_date_local: start_date_local,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      moving_time_in_seconds: moving_time_in_seconds
    } = event

    insert_activity_projection(multi,
      published: start_date_local,
      verb: "attempt",
      actor_uuid: athlete_uuid,
      object_uuid: stage_uuid,
      callback: fn %ActivityProjection{} = activity ->
        %ActivityProjection{object_name: object_name} = activity

        message =
          case stage_type do
            segment when segment in ["mountain", "rolling", "flat"] ->
              "Recorded an attempt at stage #{object_name} of " <>
                elapsed_time(elapsed_time_in_seconds)

            "race" ->
              "Recorded an attempt at stage #{object_name} of " <>
                elapsed_time(elapsed_time_in_seconds)

            "distance" ->
              "Recorded a " <>
                activity_description(activity_type) <>
                " activity for stage " <> object_name <> " of " <> distance(distance_in_metres)

            "elevation" ->
              "Recorded a " <>
                activity_description(activity_type) <>
                " activity for stage " <>
                object_name <> " climbing " <> distance(elevation_gain_in_metres)

            "duration" ->
              "Recorded a " <>
                activity_description(activity_type) <>
                " activity for stage " <>
                object_name <> " of " <> duration(moving_time_in_seconds)
          end

        %ActivityProjection{
          activity
          | message: message,
            metadata: %{
              "athlete_uuid" => athlete_uuid,
              "stage_uuid" => stage_uuid,
              "stage_name" => activity.object_name,
              "stage_type" => stage_type,
              "activity_type" => activity_type,
              "elapsed_time_in_seconds" => elapsed_time_in_seconds,
              "distance_in_metres" => distance_in_metres,
              "elevation_gain_in_metres" => elevation_gain_in_metres,
              "moving_time_in_seconds" => moving_time_in_seconds
            }
        }
      end
    )
  end

  project %StageEffortRemoved{} = event, fn multi ->
    %StageEffortRemoved{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid,
      start_date_local: start_date_local
    } = event

    query =
      case start_date_local do
        nil ->
          actor_object_activity_query("attempt", athlete_uuid, stage_uuid)

        start_date_local ->
          actor_object_activity_query(start_date_local, "attempt", athlete_uuid, stage_uuid)
      end

    Ecto.Multi.delete_all(multi, :delete_stage_effort, query, [])
  end

  project %StageEffortFlagged{} = event, %{created_at: timestamp}, fn multi ->
    %StageEffortFlagged{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      reason: reason
    } = event

    insert_activity_projection(
      multi,
      published: timestamp,
      verb: "flag",
      actor_uuid: athlete_uuid,
      object_uuid: stage_uuid,
      message: fn _actor, object ->
        "Attempt at stage #{object} of #{elapsed_time(elapsed_time_in_seconds)} flagged due to \"#{
          reason
        }\""
      end
    )
  end

  project %AthleteRankedInStageLeaderboard{goal_progress: nil} = event,
          %{created_at: timestamp},
          fn multi ->
            %AthleteRankedInStageLeaderboard{
              stage_leaderboard_uuid: stage_leaderboard_uuid,
              athlete_uuid: athlete_uuid,
              stage_uuid: stage_uuid,
              rank: rank
            } = event

            insert_activity_projection(
              multi,
              published: timestamp,
              verb: "rank",
              actor_uuid: athlete_uuid,
              object_uuid: stage_leaderboard_uuid,
              target_uuid: stage_uuid,
              message: fn _actor, _object, target ->
                "Ranked #{ordinal(rank)} in stage #{target}"
              end
            )
          end

  project %AthleteRecordedImprovedStageEffort{} = event, fn multi ->
    %AthleteRecordedImprovedStageEffort{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid,
      start_date_local: start_date_local,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres
    } = event

    multi
    |> Ecto.Multi.run(:activity, fn repo, _changes ->
      with %StageLeaderboardProjection{} = stage_leaderboard <-
             repo.get(StageLeaderboardProjection, stage_leaderboard_uuid) do
        %StageLeaderboardProjection{
          stage_type: stage_type,
          accumulate_activities: accumulate_activities
        } = stage_leaderboard

        do_insert_activity_projection(
          published: start_date_local,
          verb: "record",
          actor_uuid: athlete_uuid,
          object_uuid: stage_leaderboard_uuid,
          target_uuid: stage_uuid,
          message: fn _actor, _object, stage_name ->
            case stage_type do
              segment when segment in ["mountain", "rolling", "flat"] ->
                "Recorded a faster time for stage #{stage_name} of " <>
                  elapsed_time(elapsed_time_in_seconds)

              "race" ->
                "Recorded a faster time for stage #{stage_name} of " <>
                  elapsed_time(elapsed_time_in_seconds)

              "distance" ->
                if accumulate_activities do
                  "Recorded total activity distance for stage " <>
                    stage_name <> " of " <> distance(distance_in_metres)
                else
                  "Recorded a longer " <>
                    activity_description(activity_type) <>
                    " activity for stage " <> stage_name <> " of " <> distance(distance_in_metres)
                end

              "elevation" ->
                if accumulate_activities do
                  "Recorded total elevation gain for stage " <>
                    stage_name <> " climbing " <> distance(elevation_gain_in_metres)
                else
                  "Recorded a longer " <>
                    activity_description(activity_type) <>
                    " activity for stage " <>
                    stage_name <> " climbing " <> distance(elevation_gain_in_metres)
                end

              "duration" ->
                if accumulate_activities do
                  "Recorded total activity duration for stage " <>
                    stage_name <> " of " <> duration(moving_time_in_seconds)
                else
                  "Recorded a longer " <>
                    activity_description(activity_type) <>
                    " activity for stage " <>
                    stage_name <> " of " <> duration(moving_time_in_seconds)
                end
            end
          end
        )
      else
        _ -> {:ok, nil}
      end
    end)
  end

  project %StageLeaderboardRanked{has_goal?: false} = event, %{created_at: timestamp}, fn multi ->
    %StageLeaderboardRanked{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      stage_uuid: stage_uuid,
      new_positions: new_positions,
      positions_gained: positions_gained,
      positions_lost: positions_lost
    } = event

    multi =
      Enum.reduce(new_positions, multi, fn ranking, multi ->
        %StageLeaderboardRanked.Ranking{rank: rank, athlete_uuid: athlete_uuid} = ranking

        insert_activity_projection(
          multi,
          published: timestamp,
          verb: "rank",
          actor_uuid: athlete_uuid,
          object_uuid: stage_leaderboard_uuid,
          target_uuid: stage_uuid,
          message: fn _actor, _object, target ->
            "Ranked #{ordinal(rank)} in stage #{target}"
          end
        )
      end)

    multi =
      Enum.reduce(positions_gained, multi, fn ranking, multi ->
        %StageLeaderboardRanked.Ranking{
          rank: rank,
          athlete_uuid: athlete_uuid,
          positions_changed: positions_changed
        } = ranking

        insert_activity_projection(
          multi,
          published: timestamp,
          verb: "gain",
          actor_uuid: athlete_uuid,
          object_uuid: stage_leaderboard_uuid,
          target_uuid: stage_uuid,
          message: fn _actor, _object, target ->
            "Gained " <>
              pluralize(positions_changed, "place", "places") <>
              " in stage #{target} leaderboard, now " <> ordinal(rank)
          end
        )
      end)

    Enum.reduce(positions_lost, multi, fn ranking, multi ->
      %StageLeaderboardRanked.Ranking{
        rank: rank,
        athlete_uuid: athlete_uuid,
        positions_changed: positions_changed
      } = ranking

      insert_activity_projection(
        multi,
        published: timestamp,
        verb: "lose",
        actor_uuid: athlete_uuid,
        object_uuid: stage_leaderboard_uuid,
        target_uuid: stage_uuid,
        message: fn _actor, _object, target ->
          "Lost " <>
            pluralize(positions_changed, "place", "places") <>
            " in stage #{target} leaderboard, now " <> ordinal(rank)
        end
      )
    end)
  end

  project %StageEffortsCleared{} = event, fn multi ->
    %StageEffortsCleared{stage_uuid: stage_uuid} = event

    Ecto.Multi.delete_all(
      multi,
      :delete_stage_efforts,
      object_only_activity_query(@stage, stage_uuid),
      []
    )
  end

  project %StageLeaderboardCleared{} = event, fn multi ->
    %StageLeaderboardCleared{stage_leaderboard_uuid: stage_leaderboard_uuid} = event

    Ecto.Multi.delete_all(
      multi,
      :delete_stage_efforts,
      object_only_activity_query(@stage_leaderboard, stage_leaderboard_uuid),
      []
    )
  end

  project %AthleteAchievedStageGoal{} = event, %{created_at: timestamp}, fn multi ->
    %AthleteAchievedStageGoal{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      goal: goal,
      goal_units: goal_units
    } = event

    verb =
      case stage_type do
        "race" -> "completed"
        _stage_type -> "achieved"
      end

    insert_activity_projection(multi,
      published: timestamp,
      verb: verb,
      actor_uuid: athlete_uuid,
      object_uuid: stage_uuid,
      callback: fn %ActivityProjection{} = activity ->
        %ActivityProjection{object_name: object_name} = activity

        message =
          case stage_type do
            "race" ->
              "Completed #{object_name} distance of #{goal} " <> display_units(goal_units)

            _stage_type ->
              "Achieved stage #{object_name} goal of #{goal} " <> display_units(goal_units)
          end

        %ActivityProjection{
          activity
          | message: message,
            metadata: %{
              "athlete_uuid" => athlete_uuid,
              "stage_uuid" => stage_uuid,
              "stage_name" => object_name,
              "stage_type" => stage_type,
              "goal" => goal,
              "goal_units" => goal_units
            }
        }
      end
    )
  end

  project %StageEnded{} = event, fn multi ->
    %StageEnded{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      end_date_local: end_date_local
    } = event

    multi
    |> insert_activity_projection(
      end_date_local,
      "end",
      challenge_uuid,
      stage_uuid,
      fn _actor, object -> "Stage #{object} ended" end
    )
  end

  @doc """
  Stage leaderboards are approved by the challenge host, some period after stage ends
  """
  project %StageLeaderboardsApproved{} = event, %{created_at: timestamp}, fn multi ->
    %StageLeaderboardsApproved{
      stage_uuid: stage_uuid,
      approved_by_club_uuid: approved_by_club_uuid
    } = event

    insert_activity_projection(
      multi,
      published: timestamp,
      verb: "publish",
      actor_uuid: approved_by_club_uuid,
      object_uuid: stage_uuid,
      message: fn _actor, object -> "Published #{object} stage results" end
    )
  end

  @doc """
  Finalised leaderboard confirms stage positions
  """
  project %StageLeaderboardFinalised{has_goal?: false} = event,
          %{created_at: timestamp},
          fn multi ->
            %StageLeaderboardFinalised{stage_uuid: stage_uuid, entries: entries} = event

            entries
            |> Enum.reverse()
            |> Enum.reject(&Map.has_key?(&1, :goals))
            |> Enum.reduce(multi, fn entry, multi ->
              insert_activity_projection(
                multi,
                timestamp,
                "finish",
                entry.athlete_uuid,
                stage_uuid,
                fn _actor, object ->
                  "Finished " <> ordinal(entry.rank) <> " in stage #{object}"
                end
              )
            end)
          end

  project %AthleteAccumulatedActivityInChallengeLeaderboard{goals: nil} = event,
          %{
            created_at: timestamp
          },
          fn multi ->
            %AthleteAccumulatedActivityInChallengeLeaderboard{
              athlete_uuid: athlete_uuid,
              challenge_uuid: challenge_uuid,
              challenge_type: challenge_type,
              challenge_leaderboard_uuid: challenge_leaderboard_uuid,
              elapsed_time_in_seconds: elapsed_time_in_seconds,
              moving_time_in_seconds: moving_time_in_seconds,
              distance_in_metres: distance_in_metres,
              elevation_gain_in_metres: elevation_gain_in_metres
            } = event

            insert_activity_projection(multi,
              published: timestamp,
              verb: "accumulate",
              actor_uuid: athlete_uuid,
              object_uuid: challenge_leaderboard_uuid,
              target_uuid: challenge_uuid,
              callback: fn %ActivityProjection{} = activity ->
                %ActivityProjection{object_name: object_name, target_name: target_name} = activity

                message =
                  case challenge_type do
                    "distance" ->
                      "Accumulated " <>
                        distance(distance_in_metres) <>
                        " of activity in the " <>
                        object_name <> " leaderboard for " <> target_name

                    "elevation" ->
                      "Accumulated " <>
                        distance(elevation_gain_in_metres) <>
                        " of climbing in the " <>
                        object_name <> " leaderboard for " <> target_name

                    "duration" ->
                      "Accumulated " <>
                        duration(moving_time_in_seconds) <>
                        " of activity in the " <>
                        object_name <> " leaderboard for " <> target_name
                  end

                %ActivityProjection{
                  activity
                  | message: message,
                    metadata: %{
                      "athlete_uuid" => athlete_uuid,
                      "challenge_uuid" => challenge_uuid,
                      "challenge_name" => target_name,
                      "challenge_type" => challenge_type,
                      "elapsed_time_in_seconds" => elapsed_time_in_seconds,
                      "moving_time_in_seconds" => moving_time_in_seconds,
                      "distance_in_metres" => distance_in_metres,
                      "elevation_gain_in_metres" => elevation_gain_in_metres
                    }
                }
              end
            )
          end

  @doc """
  Points scored from place in stage leaderboard
  """
  project %AthleteAccumulatedPointsInChallengeLeaderboard{} = event,
          %{created_at: timestamp},
          fn multi ->
            %AthleteAccumulatedPointsInChallengeLeaderboard{
              athlete_uuid: athlete_uuid,
              challenge_uuid: challenge_uuid,
              challenge_type: challenge_type,
              challenge_leaderboard_uuid: challenge_leaderboard_uuid,
              points: points
            } = event

            insert_activity_projection(multi,
              published: timestamp,
              verb: "accumulate",
              actor_uuid: athlete_uuid,
              object_uuid: challenge_leaderboard_uuid,
              target_uuid: challenge_uuid,
              callback: fn %ActivityProjection{} = activity ->
                %ActivityProjection{object_name: object_name, target_name: target_name} = activity

                message =
                  "Accumulated " <>
                    pluralize(points, "point", "points") <>
                    " in the " <> object_name <> " leaderboard for " <> target_name

                %ActivityProjection{
                  activity
                  | message: message,
                    metadata: %{
                      "athlete_uuid" => athlete_uuid,
                      "challenge_uuid" => challenge_uuid,
                      "challenge_name" => target_name,
                      "challenge_type" => challenge_type,
                      "points" => points
                    }
                }
              end
            )
          end

  project %ChallengeLeaderboardRanked{has_goal?: false} = event,
          %{created_at: timestamp},
          fn multi ->
            %ChallengeLeaderboardRanked{
              challenge_leaderboard_uuid: challenge_leaderboard_uuid,
              new_entries: new_entries,
              positions_gained: positions_gained,
              positions_lost: positions_lost
            } = event

            multi =
              Enum.reduce(new_entries, multi, fn new_entry, multi ->
                insert_activity_projection(
                  multi,
                  timestamp,
                  "rank",
                  new_entry.athlete_uuid,
                  challenge_leaderboard_uuid,
                  fn _actor, object ->
                    "Ranked " <> ordinal(new_entry.rank) <> " in #{object} leaderboard"
                  end
                )
              end)

            multi =
              Enum.reduce(positions_gained, multi, fn gained, multi ->
                insert_activity_projection(
                  multi,
                  timestamp,
                  "gain",
                  gained.athlete_uuid,
                  challenge_leaderboard_uuid,
                  fn _actor, object ->
                    "Gained " <>
                      pluralize(gained.positions_changed, "place", "places") <>
                      " in #{object} leaderboard, now " <> ordinal(gained.rank)
                  end
                )
              end)

            Enum.reduce(positions_lost, multi, fn lost, multi ->
              insert_activity_projection(
                multi,
                timestamp,
                "lose",
                lost.athlete_uuid,
                challenge_leaderboard_uuid,
                fn _actor, object ->
                  "Lost " <>
                    pluralize(lost.positions_changed, "place", "places") <>
                    " in #{object} leaderboard, now " <> ordinal(lost.rank)
                end
              )
            end)
          end

  project %AthleteAchievedChallengeGoal{} = event, %{created_at: timestamp}, fn multi ->
    %AthleteAchievedChallengeGoal{athlete_uuid: athlete_uuid, challenge_uuid: challenge_uuid} =
      event

    insert_activity_projection(multi,
      published: timestamp,
      verb: "achieved",
      actor_uuid: athlete_uuid,
      object_uuid: challenge_uuid,
      callback: fn %ActivityProjection{} = activity ->
        %ActivityProjection{object_name: object_name} = activity

        message = "Achieved challenge #{object_name} goal"

        %ActivityProjection{
          activity
          | message: message,
            metadata: %{
              "athlete_uuid" => athlete_uuid,
              "challenge_uuid" => challenge_uuid,
              "challenge_name" => object_name
            }
        }
      end
    )
  end

  project %ChallengeEnded{} = event, fn multi ->
    %ChallengeEnded{challenge_uuid: challenge_uuid, end_date_local: end_date_local} = event

    multi
    |> insert_activity_projection(
      end_date_local,
      "end",
      challenge_uuid,
      challenge_uuid,
      fn _actor, object -> "Challenge #{object} ended" end
    )
  end

  project %ChallengeLeaderboardsApproved{} = event, %{created_at: timestamp}, fn multi ->
    %ChallengeLeaderboardsApproved{
      challenge_uuid: challenge_uuid,
      approved_by_club_uuid: approved_by_club_uuid
    } = event

    insert_activity_projection(
      multi,
      timestamp,
      "publish",
      approved_by_club_uuid,
      challenge_uuid,
      fn _actor, object -> "Published challenge #{object} final standings" end
    )
  end

  @doc """
  Finalised leaderboard confirms overall challenge position
  """
  project %ChallengeLeaderboardFinalised{} = event, %{created_at: timestamp}, fn multi ->
    %ChallengeLeaderboardFinalised{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      entries: entries
    } = event

    entries
    |> Enum.reverse()
    |> Enum.reduce(multi, fn entry, multi ->
      %{rank: rank, athlete_uuid: athlete_uuid} = entry

      insert_activity_projection(
        multi,
        published: timestamp,
        verb: "finish",
        actor_uuid: athlete_uuid,
        object_uuid: challenge_leaderboard_uuid,
        target_uuid: challenge_uuid,
        message: fn _actor, object, target ->
          "Finished " <> ordinal(rank) <> " in #{target} #{object} competition"
        end
      )
    end)
  end

  def error({:error, error}, event, _failure_context) do
    Logger.error(fn ->
      "Activity feed projector failed to handled event " <>
        inspect(event) <> " due to: " <> inspect(error)
    end)

    :skip
  end

  defp get_actor(uuid) do
    case Repo.get(ActorProjection, uuid) do
      nil ->
        Logger.warn(fn -> "Actor not found: #{uuid}" end)
        {:error, :actor_not_found}

      actor ->
        {:ok, actor}
    end
  end

  defp insert_activity_projection(
         %Ecto.Multi{} = multi,
         published,
         verb,
         actor_uuid,
         object_uuid,
         message
       ) do
    insert_activity_projection(multi,
      published: published,
      verb: verb,
      actor_uuid: actor_uuid,
      object_uuid: object_uuid,
      message: message
    )
  end

  defp insert_activity_projection(%Ecto.Multi{} = multi, opts) do
    Ecto.Multi.run(multi, UUID.uuid4(), fn _repo, _changes ->
      do_insert_activity_projection(opts)
    end)
  end

  defp do_insert_activity_projection(options) do
    case build_activity_projection(options) do
      {:ok, activity} ->
        %ActivityProjection{
          actor_name: actor_name,
          object_name: object_name,
          target_name: target_name
        } = activity

        activity =
          case Keyword.get(options, :message) do
            message when is_binary(message) ->
              %ActivityProjection{activity | message: message}

            fun when is_function(fun, 2) ->
              message = apply(fun, [actor_name, object_name])

              %ActivityProjection{activity | message: message}

            fun when is_function(fun, 3) ->
              message = apply(fun, [actor_name, object_name, target_name])

              %ActivityProjection{activity | message: message}

            nil ->
              activity
          end

        activity =
          case Keyword.get(options, :callback) do
            callback when is_function(callback, 1) ->
              apply(callback, [activity])

            nil ->
              activity
          end

        Repo.insert(activity)

      {:error, :invalid_activity} ->
        {:ok, nil}
    end
  end

  defp build_activity_projection(opts) do
    %{
      published: Keyword.get(opts, :published),
      verb: Keyword.get(opts, :verb)
    }
    |> include_actor(Keyword.get(opts, :actor_uuid), :actor)
    |> include_actor(Keyword.get(opts, :object_uuid), :object)
    |> include_actor(Keyword.get(opts, :target_uuid), :target)
    |> create_activity_projection()
  end

  defp include_actor(params, nil, _type), do: params

  defp include_actor(params, actor_uuid, type) do
    case get_actor(actor_uuid) do
      {:ok, actor} -> Map.put(params, type, actor)
      {:error, :actor_not_found} -> params
    end
  end

  defp create_activity_projection(
         %{
           published: published,
           verb: verb,
           actor: actor,
           object: object
         } = params
       )
       when is_binary(verb) do
    projection = %ActivityProjection{
      published: NaiveDateTime.truncate(published, :second),
      actor_type: actor.actor_type,
      actor_uuid: actor.actor_uuid,
      actor_name: actor.actor_name,
      actor_image: actor.actor_image,
      verb: verb,
      object_type: object.actor_type,
      object_uuid: object.actor_uuid,
      object_name: object.actor_name,
      object_image: object.actor_image,
      message: Map.get(params, :message)
    }

    projection =
      case Map.get(params, :target) do
        nil ->
          projection

        target ->
          %ActivityProjection{
            projection
            | target_type: target.actor_type,
              target_uuid: target.actor_uuid,
              target_name: target.actor_name,
              target_image: target.actor_image
          }
      end

    {:ok, projection}
  end

  defp create_activity_projection(_params), do: {:error, :invalid_activity}

  defp record_actor(multi, type, uuid, name, image \\ nil)

  defp record_actor(multi, type, uuid, name, image) do
    multi
    |> upsert_actor(type, uuid, name, image)
    |> update_activity_images(type, uuid, image)
  end

  defp upsert_actor(multi, type, uuid, name, image) do
    actor = %ActorProjection{
      actor_uuid: uuid,
      actor_type: type,
      actor_name: name,
      actor_image: image
    }

    Ecto.Multi.insert(multi, UUID.uuid4(), actor,
      on_conflict: [set: [actor_name: name, actor_image: image]],
      conflict_target: [:actor_uuid]
    )
  end

  defp delete_actor(multi, type, uuid) do
    multi
    |> Ecto.Multi.delete_all(UUID.uuid4(), actor_query(type, uuid), [])
    |> Ecto.Multi.delete_all(UUID.uuid4(), actor_activity_query(type, uuid), [])
  end

  defp update_actor_image(multi, type, uuid, image) do
    multi
    |> Ecto.Multi.update_all(UUID.uuid4(), actor_query(type, uuid), set: [actor_image: image])
  end

  defp update_activity_images(multi, type, uuid, image) do
    multi
    |> Ecto.Multi.update_all(UUID.uuid4(), actor_only_activity_query(type, uuid),
      set: [actor_image: image]
    )
    |> Ecto.Multi.update_all(UUID.uuid4(), object_only_activity_query(type, uuid),
      set: [object_image: image]
    )
    |> Ecto.Multi.update_all(UUID.uuid4(), target_only_activity_query(type, uuid),
      set: [target_image: image]
    )
  end

  defp actor_query(type, actor_uuid) do
    from(a in ActorProjection,
      where: a.actor_type == ^type and a.actor_uuid == ^actor_uuid
    )
  end

  defp actor_activity_query(type, actor_uuid) do
    from(a in ActivityProjection,
      where:
        (a.actor_type == ^type and a.actor_uuid == ^actor_uuid) or
          (a.object_type == ^type and a.object_uuid == ^actor_uuid) or
          (a.target_type == ^type and a.target_uuid == ^actor_uuid)
    )
  end

  defp actor_object_activity_query(actor_uuid, object_uuid) do
    from(a in ActivityProjection,
      where: a.actor_uuid == ^actor_uuid and a.object_uuid == ^object_uuid
    )
  end

  defp actor_object_activity_query(verb, actor_uuid, object_uuid) do
    from(a in ActivityProjection,
      where: a.actor_uuid == ^actor_uuid and a.object_uuid == ^object_uuid and a.verb == ^verb
    )
  end

  defp actor_object_activity_query(published, verb, actor_uuid, object_uuid) do
    from(a in ActivityProjection,
      where:
        a.published == ^published and a.actor_uuid == ^actor_uuid and
          a.object_uuid == ^object_uuid and a.verb == ^verb
    )
  end

  defp actor_only_activity_query(type, actor_uuid) do
    from(a in ActivityProjection,
      where: a.actor_type == ^type and a.actor_uuid == ^actor_uuid
    )
  end

  defp object_only_activity_query(type, object_uuid) do
    from(a in ActivityProjection,
      where: a.object_type == ^type and a.object_uuid == ^object_uuid
    )
  end

  defp target_only_activity_query(type, target_uuid) do
    from(a in ActivityProjection,
      where: a.target_type == ^type and a.target_uuid == ^target_uuid
    )
  end

  # Get challenge competitors from challenge event stream for given version.
  defp challenge_competitors(challenge_uuid, version) do
    challenge_uuid
    |> challenge_events(version)
    |> Stream.filter(fn
      %CompetitorJoinedChallenge{} -> true
      %CompetitorsJoinedChallenge{} -> true
      %CompetitorLeftChallenge{} -> true
      %CompetitorExcludedFromChallenge{} -> true
      _event -> false
    end)
    |> Enum.reduce(MapSet.new(), fn event, competitors ->
      case event do
        %CompetitorJoinedChallenge{athlete_uuid: athlete_uuid} ->
          MapSet.put(competitors, athlete_uuid)

        %CompetitorsJoinedChallenge{competitors: joined} ->
          joined = joined |> Enum.map(& &1.athlete_uuid) |> MapSet.new()
          MapSet.union(competitors, joined)

        %CompetitorLeftChallenge{athlete_uuid: athlete_uuid} ->
          MapSet.delete(competitors, athlete_uuid)

        %CompetitorExcludedFromChallenge{athlete_uuid: athlete_uuid} ->
          MapSet.delete(competitors, athlete_uuid)
      end
    end)
  end

  # Is the challenge approved for the given version?
  defp challenge_approved?(challenge_uuid, version) do
    challenge_uuid
    |> challenge_events(version)
    |> Stream.filter(fn
      %ChallengeApproved{} -> true
      _ -> false
    end)
    |> Enum.any?()
  end

  defp challenge_events(challenge_uuid, version) do
    challenge_uuid
    |> EventStore.stream_forward()
    |> Stream.take(version)
    |> Stream.map(& &1.data)
  end

  defp ordinal(number), do: Number.Human.number_to_ordinal(number)

  defp pluralize(1, singular, _plural), do: "1 #{singular}"
  defp pluralize(count, _singular, plural), do: "#{count} #{plural}"

  defp activity_description("Ride"), do: "ride"
  defp activity_description("Run"), do: "run"
  defp activity_description("Hike"), do: "hike"
  defp activity_description("Swim"), do: "swim"
  defp activity_description("VirtualRide"), do: "virtual ride"
  defp activity_description("VirtualRun"), do: "virtual run"
  defp activity_description("Walk"), do: "walk"
  defp activity_description(nil), do: "unknown"
  defp activity_description(activity_type), do: String.downcase(activity_type)

  def display_units("kilometres"), do: "km"
  def display_units("feet"), do: "ft"
  def display_units(units), do: units
end
