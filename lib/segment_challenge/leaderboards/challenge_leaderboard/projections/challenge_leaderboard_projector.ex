defmodule SegmentChallenge.Projections.ChallengeLeaderboardProjector do
  use Commanded.Projections.Ecto, name: "ChallengeLeaderboardProjection"

  use SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases

  alias SegmentChallenge.Projections.AthleteCompetitorProjection
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Projections.ChallengeLeaderboardProjection
  alias SegmentChallenge.Projections.ChallengeLeaderboardEntryProjection
  alias SegmentChallenge.Repo

  project %ChallengeLeaderboardCreated{} = event, fn multi ->
    %ChallengeLeaderboardCreated{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      gender: gender,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal?: has_goal
    } = event

    multi
    |> Ecto.Multi.run(:challenge, fn _repo, _changes -> lookup_challenge(challenge_uuid) end)
    |> Ecto.Multi.run(:challenge_leaderboard, fn _repo, changes ->
      %{
        challenge: %ChallengeProjection{
          goal: goal,
          goal_units: goal_units,
          goal_recurrence: goal_recurrence,
          accumulate_activities: accumulate_activities
        }
      } = changes

      challenge_leaderboard = %ChallengeLeaderboardProjection{
        challenge_leaderboard_uuid: challenge_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        challenge_type: challenge_type,
        name: name,
        description: description,
        gender: gender,
        rank_by: rank_by,
        rank_order: rank_order,
        accumulate_activities: accumulate_activities,
        has_goal: has_goal,
        goal: goal,
        goal_units: goal_units,
        goal_recurrence: goal_recurrence
      }

      Repo.insert(challenge_leaderboard)
    end)
  end

  project %AthleteAccumulatedActivityInChallengeLeaderboard{} = event, fn multi ->
    %AthleteAccumulatedActivityInChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      goals: goals,
      goal_progress: goal_progress,
      activity_count: activity_count,
      athlete_uuid: athlete_uuid,
      gender: gender
    } = event

    multi
    |> Ecto.Multi.run(:athlete, fn _repo, _changes -> lookup_athlete(athlete_uuid) end)
    |> Ecto.Multi.run(:challenge_leaderboard_entry, fn _repo, %{athlete: athlete} ->
      case Repo.one(entry_query(challenge_leaderboard_uuid, athlete_uuid)) do
        nil ->
          entry = %ChallengeLeaderboardEntryProjection{
            challenge_leaderboard_uuid: challenge_leaderboard_uuid,
            challenge_uuid: challenge_uuid,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            moving_time_in_seconds: moving_time_in_seconds,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            goals: goals,
            goal_progress: %{stage_uuid => goal_progress},
            activity_count: activity_count,
            athlete_uuid: athlete_uuid,
            athlete_gender: gender,
            athlete_firstname: athlete.firstname,
            athlete_lastname: athlete.lastname,
            athlete_profile: athlete.profile
          }

          Repo.insert(entry)

        entry ->
          %ChallengeLeaderboardEntryProjection{
            elapsed_time_in_seconds: existing_elapsed_time_in_seconds,
            moving_time_in_seconds: existing_moving_time_in_seconds,
            distance_in_metres: existing_distance_in_metres,
            elevation_gain_in_metres: existing_elevation_gain_in_metres,
            goals: existing_goals,
            goal_progress: existing_goal_progress,
            activity_count: existing_activity_count
          } = entry

          changeset =
            Ecto.Changeset.change(entry,
              elapsed_time_in_seconds: existing_elapsed_time_in_seconds + elapsed_time_in_seconds,
              moving_time_in_seconds: existing_moving_time_in_seconds + moving_time_in_seconds,
              distance_in_metres: existing_distance_in_metres + distance_in_metres,
              elevation_gain_in_metres:
                existing_elevation_gain_in_metres + elevation_gain_in_metres,
              goals: existing_goals + goals,
              goal_progress: Map.put(existing_goal_progress, stage_uuid, goal_progress),
              activity_count: existing_activity_count + activity_count
            )

          Repo.update(changeset)
      end
    end)
  end

  project %AthleteAccumulatedPointsInChallengeLeaderboard{} = event, fn multi ->
    %AthleteAccumulatedPointsInChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      points: points,
      athlete_uuid: athlete_uuid,
      gender: gender
    } = event

    multi
    |> Ecto.Multi.run(:athlete, fn _repo, _changes -> lookup_athlete(athlete_uuid) end)
    |> Ecto.Multi.run(:challenge_leaderboard_entry, fn _repo, %{athlete: athlete} ->
      entry = %ChallengeLeaderboardEntryProjection{
        challenge_leaderboard_uuid: challenge_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        points: points,
        athlete_uuid: athlete_uuid,
        athlete_gender: gender,
        athlete_firstname: athlete.firstname,
        athlete_lastname: athlete.lastname,
        athlete_profile: athlete.profile
      }

      Repo.insert(entry,
        on_conflict: [inc: [points: points]],
        conflict_target: [:challenge_leaderboard_uuid, :athlete_uuid]
      )
    end)
  end

  project %AthleteActivityAdjustedInChallengeLeaderboard{} = event, fn multi ->
    %AthleteActivityAdjustedInChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      stage_uuid: stage_uuid,
      elapsed_time_in_seconds_adjustment: elapsed_time_in_seconds_adjustment,
      moving_time_in_seconds_adjustment: moving_time_in_seconds_adjustment,
      distance_in_metres_adjustment: distance_in_metres_adjustment,
      elevation_gain_in_metres_adjustment: elevation_gain_in_metres_adjustment,
      goals_adjustment: goals_adjustment,
      activity_count_adjustment: activity_count_adjustment,
      athlete_uuid: athlete_uuid
    } = event

    Ecto.Multi.run(multi, :challenge_leaderboard_entry, fn _repo, _changes ->
      case Repo.one(entry_query(challenge_leaderboard_uuid, athlete_uuid)) do
        nil ->
          {:ok, nil}

        entry ->
          %ChallengeLeaderboardEntryProjection{
            elapsed_time_in_seconds: existing_elapsed_time_in_seconds,
            moving_time_in_seconds: existing_moving_time_in_seconds,
            distance_in_metres: existing_distance_in_metres,
            elevation_gain_in_metres: existing_elevation_gain_in_metres,
            goals: existing_goals,
            goal_progress: existing_goal_progress,
            activity_count: activity_count
          } = entry

          changeset =
            Ecto.Changeset.change(entry,
              elapsed_time_in_seconds:
                existing_elapsed_time_in_seconds + elapsed_time_in_seconds_adjustment,
              moving_time_in_seconds:
                existing_moving_time_in_seconds + moving_time_in_seconds_adjustment,
              distance_in_metres: existing_distance_in_metres + distance_in_metres_adjustment,
              elevation_gain_in_metres:
                existing_elevation_gain_in_metres + elevation_gain_in_metres_adjustment,
              goals: existing_goals + goals_adjustment,
              goal_progress: Map.delete(existing_goal_progress, stage_uuid),
              activity_count: activity_count + activity_count_adjustment
            )

          Repo.update(changeset)
      end
    end)
  end

  project %AthletePointsAdjustedInChallengeLeaderboard{} = event, fn multi ->
    %AthletePointsAdjustedInChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      points_adjustment: points_adjustment,
      athlete_uuid: athlete_uuid
    } = event

    Ecto.Multi.update_all(
      multi,
      :challenge_leaderboard,
      entry_query(challenge_leaderboard_uuid, athlete_uuid),
      inc: [points: points_adjustment]
    )
  end

  project %ChallengeLeaderboardRanked{
            challenge_leaderboard_uuid: challenge_leaderboard_uuid,
            new_entries: new_entries,
            positions_gained: positions_gained,
            positions_lost: positions_lost
          },
          fn multi ->
            Enum.reduce(new_entries ++ positions_gained ++ positions_lost, multi, fn change,
                                                                                     multi ->
              Ecto.Multi.update_all(
                multi,
                "challenge_leaderboard_entry_#{change.athlete_uuid}",
                entry_query(challenge_leaderboard_uuid, change.athlete_uuid),
                set: [rank: change.rank]
              )
            end)
          end

  project %AthleteRemovedFromChallengeLeaderboard{
            challenge_leaderboard_uuid: challenge_leaderboard_uuid,
            athlete_uuid: athlete_uuid
          },
          fn multi ->
            multi
            |> Ecto.Multi.delete_all(
              :challenge_leaderboard_entry,
              entry_query(challenge_leaderboard_uuid, athlete_uuid)
            )
          end

  project %ChallengeLeaderboardRemoved{challenge_leaderboard_uuid: challenge_leaderboard_uuid},
          fn multi ->
            multi
            |> Ecto.Multi.delete_all(
              :challenge_leaderboard_entries,
              entry_query(challenge_leaderboard_uuid)
            )
            |> Ecto.Multi.delete_all(
              :challenge_leaderboard,
              leaderboard_query(challenge_leaderboard_uuid)
            )
          end

  defp lookup_challenge(challenge_uuid) do
    case Repo.get(ChallengeProjection, challenge_uuid) do
      %ChallengeProjection{} = challenge -> {:ok, challenge}
      nil -> {:error, :challenge_not_found}
    end
  end

  defp lookup_athlete(athlete_uuid) do
    case Repo.get(AthleteCompetitorProjection, athlete_uuid) do
      %AthleteCompetitorProjection{} = athlete -> {:ok, athlete}
      nil -> {:ok, %{firstname: "Strava", lastname: "Athlete", profile: nil}}
    end
  end

  defp leaderboard_query(challenge_leaderboard_uuid) do
    from(leaderboard in ChallengeLeaderboardProjection,
      where: leaderboard.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid
    )
  end

  defp entry_query(challenge_leaderboard_uuid) do
    from(entry in ChallengeLeaderboardEntryProjection,
      where: entry.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid
    )
  end

  defp entry_query(challenge_leaderboard_uuid, athlete_uuid) do
    from(entry in ChallengeLeaderboardEntryProjection,
      where:
        entry.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid and
          entry.athlete_uuid == ^athlete_uuid
    )
  end
end
