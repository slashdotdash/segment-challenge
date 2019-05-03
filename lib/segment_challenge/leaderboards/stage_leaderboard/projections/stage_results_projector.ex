defmodule SegmentChallenge.Leaderboards.StageLeaderboard.StageResultsProjector do
  use Commanded.Projections.Ecto, name: "StageResultProjection"
  use SegmentChallenge.Challenges.Challenge.Aliases
  use SegmentChallenge.Stages.Stage.Aliases
  use SegmentChallenge.Leaderboards.StageLeaderboard.Aliases
  use SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases

  alias SegmentChallenge.Projections.AthleteCompetitorProjection
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.ChallengeLeaderboardProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.ChallengeStageProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.StageResultProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.StageResultEntryProjection
  alias SegmentChallenge.Repo

  project %StageCreated{} = event, fn multi ->
    %StageCreated{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_number: stage_number
    } = event

    Ecto.Multi.run(multi, :stage_results, fn _repo, changes ->
      Repo.insert!(%ChallengeStageProjection{
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        stage_number: stage_number
      })

      challenge_leaderboards = challenge_uuid |> challenge_leaderboards_query() |> Repo.all()

      for leaderboard <- challenge_leaderboards do
        %ChallengeLeaderboardProjection{
          challenge_uuid: challenge_uuid,
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          name: name,
          description: description,
          gender: gender,
          rank_by: rank_by,
          rank_order: rank_order,
          goal: goal,
          goal_units: goal_units,
          goal_recurrence: goal_recurrence
        } = leaderboard

        Repo.insert!(%StageResultProjection{
          challenge_uuid: challenge_uuid,
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          stage_uuid: stage_uuid,
          stage_number: stage_number,
          name: name,
          description: description,
          gender: gender,
          rank_by: rank_by,
          rank_order: rank_order,
          goal: goal,
          goal_units: goal_units,
          goal_recurrence: goal_recurrence
        })
      end

      copy_previous_stage_entries(challenge_uuid, stage_uuid, stage_number)

      {:ok, changes}
    end)
  end

  project %ChallengeLeaderboardCreated{} = event, fn multi ->
    %ChallengeLeaderboardCreated{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      name: name,
      description: description,
      gender: gender,
      rank_by: rank_by,
      rank_order: rank_order
    } = event

    multi
    |> Ecto.Multi.run(:challenge, fn _repo, _changes -> lookup_challenge(challenge_uuid) end)
    |> Ecto.Multi.run(:stage_results, fn _repo, changes ->
      %{
        challenge: %ChallengeProjection{
          has_goal: has_goal,
          goal: goal,
          goal_units: goal_units,
          goal_recurrence: goal_recurrence
        }
      } = changes

      Repo.insert!(%ChallengeLeaderboardProjection{
        challenge_uuid: challenge_uuid,
        challenge_leaderboard_uuid: challenge_leaderboard_uuid,
        name: name,
        description: description,
        gender: gender,
        rank_by: rank_by,
        rank_order: rank_order,
        has_goal: has_goal,
        goal: goal,
        goal_units: goal_units,
        goal_recurrence: goal_recurrence
      })

      challenge_stages = challenge_uuid |> challenge_stages_query() |> Repo.all()

      for stage <- challenge_stages do
        %ChallengeStageProjection{stage_uuid: stage_uuid, stage_number: stage_number} = stage

        stage_result = %StageResultProjection{
          challenge_uuid: challenge_uuid,
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          stage_uuid: stage_uuid,
          stage_number: stage_number,
          name: name,
          description: description,
          gender: gender,
          rank_by: rank_by,
          rank_order: rank_order,
          goal: goal,
          goal_units: goal_units,
          goal_recurrence: goal_recurrence
        }

        Repo.insert!(stage_result)
      end

      {:ok, changes}
    end)
  end

  project %StageEnded{} = event, fn multi ->
    %StageEnded{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = event

    Ecto.Multi.run(multi, :stage_results, fn _repo, changes ->
      case Repo.one(query_stage_number(stage_uuid)) do
        nil ->
          nil

        stage_number ->
          Repo.update_all(
            reset_stage_result_entries(challenge_uuid, stage_number),
            []
          )
      end

      {:ok, changes}
    end)
  end

  project %StageLeaderboardFinalised{} = event, fn multi ->
    %StageLeaderboardFinalised{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = event

    Ecto.Multi.run(multi, :stage_results, fn _repo, changes ->
      case Repo.one(query_stage_number(stage_uuid)) do
        nil ->
          nil

        stage_number ->
          Repo.update_all(update_stage_results_by_challenge(challenge_uuid, stage_number), [])
      end

      {:ok, changes}
    end)
  end

  project %AthleteAccumulatedActivityInChallengeLeaderboard{} = event, fn multi ->
    %AthleteAccumulatedActivityInChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      athlete_uuid: athlete_uuid,
      gender: gender,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      goals: goals,
      activity_count: activity_count
    } = event

    update_stage_result(multi, challenge_leaderboard_uuid, fn stage_result ->
      case Repo.one(entry_query(stage_result, athlete_uuid)) do
        nil ->
          {:ok, athlete} = lookup_athlete(athlete_uuid)

          new_entry = %StageResultEntryProjection{
            challenge_uuid: challenge_uuid,
            challenge_leaderboard_uuid: challenge_leaderboard_uuid,
            stage_uuid: stage_result.stage_uuid,
            stage_number: stage_result.stage_number,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            moving_time_in_seconds: moving_time_in_seconds,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            elapsed_time_in_seconds_gained: elapsed_time_in_seconds,
            moving_time_in_seconds_gained: moving_time_in_seconds,
            distance_in_metres_gained: distance_in_metres,
            elevation_gain_in_metres_gained: elevation_gain_in_metres,
            goals_gained: goals,
            goals: goals,
            activity_count: activity_count,
            athlete_uuid: athlete_uuid,
            athlete_firstname: athlete.firstname,
            athlete_lastname: athlete.lastname,
            athlete_gender: gender,
            athlete_profile: athlete.profile
          }

          Repo.insert(new_entry)

        _entry ->
          Repo.update_all(entry_query(stage_result, athlete_uuid),
            inc: [
              elapsed_time_in_seconds: elapsed_time_in_seconds,
              moving_time_in_seconds: moving_time_in_seconds,
              distance_in_metres: distance_in_metres,
              elevation_gain_in_metres: elevation_gain_in_metres,
              goals: goals,
              activity_count: activity_count
            ],
            set: [
              elapsed_time_in_seconds_gained: elapsed_time_in_seconds,
              moving_time_in_seconds_gained: moving_time_in_seconds,
              distance_in_metres_gained: distance_in_metres,
              elevation_gain_in_metres_gained: elevation_gain_in_metres,
              goals_gained: goals
            ]
          )
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

    update_stage_result(multi, challenge_leaderboard_uuid, fn stage_result ->
      case Repo.one(entry_query(stage_result, athlete_uuid)) do
        nil ->
          {:ok, athlete} = lookup_athlete(athlete_uuid)

          new_entry = %StageResultEntryProjection{
            challenge_uuid: challenge_uuid,
            challenge_leaderboard_uuid: challenge_leaderboard_uuid,
            stage_uuid: stage_result.stage_uuid,
            stage_number: stage_result.stage_number,
            points: points,
            points_gained: points,
            athlete_uuid: athlete_uuid,
            athlete_firstname: athlete.firstname,
            athlete_lastname: athlete.lastname,
            athlete_gender: gender,
            athlete_profile: athlete.profile
          }

          Repo.insert(new_entry)

        _entry ->
          Repo.update_all(entry_query(stage_result, athlete_uuid),
            inc: [
              points: points
            ],
            set: [
              points_gained: points
            ]
          )
      end
    end)
  end

  project %AthleteActivityAdjustedInChallengeLeaderboard{} = event, fn multi ->
    %AthleteActivityAdjustedInChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      athlete_uuid: athlete_uuid,
      elapsed_time_in_seconds_adjustment: elapsed_time_in_seconds_adjustment,
      moving_time_in_seconds_adjustment: moving_time_in_seconds_adjustment,
      distance_in_metres_adjustment: distance_in_metres_adjustment,
      elevation_gain_in_metres_adjustment: elevation_gain_in_metres_adjustment,
      goals_adjustment: goals_adjustment,
      activity_count_adjustment: activity_count_adjustment
    } = event

    update_stage_result(multi, challenge_leaderboard_uuid, fn stage_result ->
      Repo.update_all(entry_query(stage_result, athlete_uuid),
        inc: [
          elapsed_time_in_seconds: elapsed_time_in_seconds_adjustment,
          elapsed_time_in_seconds_gained: elapsed_time_in_seconds_adjustment,
          moving_time_in_seconds: moving_time_in_seconds_adjustment,
          moving_time_in_seconds_gained: moving_time_in_seconds_adjustment,
          distance_in_metres: distance_in_metres_adjustment,
          distance_in_metres_gained: distance_in_metres_adjustment,
          elevation_gain_in_metres: elevation_gain_in_metres_adjustment,
          elevation_gain_in_metres_gained: elevation_gain_in_metres_adjustment,
          goals: goals_adjustment,
          goals_gained: goals_adjustment,
          activity_count: activity_count_adjustment
        ]
      )
    end)
  end

  project %AthletePointsAdjustedInChallengeLeaderboard{} = event, fn multi ->
    %AthletePointsAdjustedInChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      athlete_uuid: athlete_uuid,
      points_adjustment: points_adjustment
    } = event

    update_stage_result(multi, challenge_leaderboard_uuid, fn stage_result ->
      Repo.update_all(entry_query(stage_result, athlete_uuid),
        inc: [
          points: points_adjustment,
          points_gained: points_adjustment
        ]
      )
    end)
  end

  project %ChallengeLeaderboardRanked{} = event, fn multi ->
    %ChallengeLeaderboardRanked{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      new_entries: new_entries,
      positions_gained: positions_gained,
      positions_lost: positions_lost
    } = event

    update_stage_result(multi, challenge_leaderboard_uuid, fn stage_result ->
      for change <- new_entries do
        Repo.update_all(entry_query(stage_result, change.athlete_uuid),
          set: [
            rank: change.rank,
            rank_change: nil
          ]
        )
      end

      for change <- positions_gained do
        Repo.update_all(entry_query(stage_result, change.athlete_uuid),
          set: [
            rank: change.rank,
            rank_change: change.positions_changed
          ]
        )
      end

      for change <- positions_lost do
        Repo.update_all(entry_query(stage_result, change.athlete_uuid),
          set: [
            rank: change.rank,
            rank_change: -change.positions_changed
          ]
        )
      end
    end)
  end

  project %AthleteRemovedFromChallengeLeaderboard{} = event, fn multi ->
    %AthleteRemovedFromChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      athlete_uuid: athlete_uuid
    } = event

    update_stage_result(multi, challenge_leaderboard_uuid, fn stage_result ->
      Repo.delete_all(entry_query(stage_result, athlete_uuid))
    end)
  end

  project %ChallengeLeaderboardRemoved{} = event, fn multi ->
    %ChallengeLeaderboardRemoved{challenge_leaderboard_uuid: challenge_leaderboard_uuid} = event

    multi
    |> Ecto.Multi.delete_all(
      :remove_stage_result_challenge_leaderboard,
      challenge_leaderboard_query(challenge_leaderboard_uuid)
    )
    |> Ecto.Multi.delete_all(
      :remove_stage_result_entries,
      entry_by_leaderboard_query(challenge_leaderboard_uuid)
    )
    |> Ecto.Multi.delete_all(
      :remove_stage_results,
      result_by_leaderboard_query(challenge_leaderboard_uuid)
    )
  end

  project %StageDeleted{} = event, fn multi ->
    %StageDeleted{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = event

    multi
    |> Ecto.Multi.delete_all(
      :remove_stage_result_challenge_stages,
      challenge_stage_query(challenge_uuid, stage_uuid)
    )
    |> Ecto.Multi.delete_all(:remove_stage_result_entries, entry_by_stage_query(stage_uuid))
    |> Ecto.Multi.delete_all(:remove_stage_results, result_by_stage_query(stage_uuid))
  end

  defp update_stage_result(multi, challenge_leaderboard_uuid, callback) do
    Ecto.Multi.run(multi, :stage_results, fn _repo, changes ->
      current_stage_number =
        case Repo.one(query_current_stage_number_by_leaderboard(challenge_leaderboard_uuid)) do
          nil -> 1
          stage_number -> stage_number
        end

      stage_results =
        challenge_leaderboard_uuid
        |> query_stages_by_leaderboard(current_stage_number)
        |> Repo.all()

      for stage_result <- stage_results do
        apply(callback, [stage_result])
      end

      {:ok, changes}
    end)
  end

  # Copy any existing stage result entries from previous stage.
  defp copy_previous_stage_entries(challenge_uuid, stage_uuid, stage_number) do
    entries =
      challenge_uuid
      |> entry_by_challenge_and_stage_number_query(stage_number - 1)
      |> Repo.all()

    for %StageResultEntryProjection{} = entry <- entries do
      new_entry = %StageResultEntryProjection{
        entry
        | id: nil,
          stage_uuid: stage_uuid,
          stage_number: stage_number,
          rank_change: 0,
          points_gained: 0,
          elapsed_time_in_seconds_gained: 0,
          moving_time_in_seconds_gained: 0,
          distance_in_metres_gained: 0.0,
          elevation_gain_in_metres_gained: 0.0,
          goals_gained: 0,
          activity_count: 0
      }

      Repo.insert!(new_entry)
    end
  end

  defp lookup_challenge(challenge_uuid) do
    case Repo.get(ChallengeProjection, challenge_uuid) do
      %ChallengeProjection{} = challenge -> {:ok, challenge}
      nil -> {:error, :challenge_not_found}
    end
  end

  defp challenge_leaderboard_query(challenge_leaderboard_uuid) do
    from(cl in ChallengeLeaderboardProjection,
      where: cl.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid
    )
  end

  defp challenge_leaderboards_query(challenge_uuid) do
    from(cl in ChallengeLeaderboardProjection,
      where: cl.challenge_uuid == ^challenge_uuid
    )
  end

  defp challenge_stages_query(challenge_uuid) do
    from(cs in ChallengeStageProjection,
      where: cs.challenge_uuid == ^challenge_uuid
    )
  end

  defp challenge_stage_query(challenge_uuid, stage_uuid) do
    from(cs in ChallengeStageProjection,
      where: cs.challenge_uuid == ^challenge_uuid and cs.stage_uuid == ^stage_uuid
    )
  end

  defp update_stage_results_by_challenge(challenge_uuid, stage_number) do
    from(sr in StageResultProjection,
      where: sr.challenge_uuid == ^challenge_uuid,
      update: [
        set: [
          current_stage_number: ^stage_number
        ]
      ]
    )
  end

  defp reset_stage_result_entries(challenge_uuid, stage_number) do
    from(e in StageResultEntryProjection,
      where: e.challenge_uuid == ^challenge_uuid and e.stage_number >= ^stage_number,
      update: [
        set: [
          points_gained: 0,
          elapsed_time_in_seconds_gained: 0,
          moving_time_in_seconds_gained: 0,
          distance_in_metres_gained: 0.0,
          elevation_gain_in_metres_gained: 0.0,
          goals_gained: 0,
          rank_change: 0
        ]
      ]
    )
  end

  defp query_stage_number(stage_uuid) do
    from(sr in StageResultProjection,
      where: sr.stage_uuid == ^stage_uuid,
      limit: 1,
      select: sr.stage_number
    )
  end

  defp query_current_stage_number_by_leaderboard(challenge_leaderboard_uuid) do
    from(sr in StageResultProjection,
      where:
        sr.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid and
          not is_nil(sr.current_stage_number),
      limit: 1,
      select: sr.current_stage_number
    )
  end

  defp query_stages_by_leaderboard(challenge_leaderboard_uuid, current_stage_number) do
    from(sr in StageResultProjection,
      where:
        sr.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid and
          sr.stage_number >= ^current_stage_number
    )
  end

  defp entry_query(%StageResultProjection{} = result, athlete_uuid) do
    from(e in StageResultEntryProjection,
      where:
        e.challenge_uuid == ^result.challenge_uuid and
          e.challenge_leaderboard_uuid == ^result.challenge_leaderboard_uuid and
          e.stage_uuid == ^result.stage_uuid and e.athlete_uuid == ^athlete_uuid
    )
  end

  defp entry_by_leaderboard_query(challenge_leaderboard_uuid) do
    from(e in StageResultEntryProjection,
      where: e.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid
    )
  end

  defp result_by_leaderboard_query(challenge_leaderboard_uuid) do
    from(sr in StageResultProjection,
      where: sr.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid
    )
  end

  defp entry_by_stage_query(stage_uuid) do
    from(e in StageResultEntryProjection,
      where: e.stage_uuid == ^stage_uuid
    )
  end

  defp result_by_stage_query(stage_uuid) do
    from(sr in StageResultProjection,
      where: sr.stage_uuid == ^stage_uuid
    )
  end

  defp entry_by_challenge_and_stage_number_query(challenge_uuid, stage_number) do
    from(e in StageResultEntryProjection,
      where: e.challenge_uuid == ^challenge_uuid and e.stage_number == ^stage_number
    )
  end

  defp lookup_athlete(athlete_uuid) do
    case Repo.get(AthleteCompetitorProjection, athlete_uuid) do
      %AthleteCompetitorProjection{} = athlete -> {:ok, athlete}
      nil -> {:ok, %{firstname: "Strava", lastname: "Athlete", profile: nil}}
    end
  end
end
