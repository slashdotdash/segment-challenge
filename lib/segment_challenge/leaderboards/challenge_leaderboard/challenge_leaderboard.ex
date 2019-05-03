defmodule SegmentChallenge.Leaderboards.ChallengeLeaderboard do
  @moduledoc """
  Challenge leaderboards represent the overall ranking of athletes for a challenge. Based on their accumlated points.
  """

  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :challenge_type,
    :name,
    :description,
    :rank_by,
    :rank_order,
    :gender,
    has_goal?: false,
    # points array or associative map of stage type => points array
    points: [],
    entries: %{},
    limited_competitors: MapSet.new(),
    finalised?: false,
    removed?: false,
    goal_achievers: MapSet.new()
  ]

  @stage_types [:mountain, :rolling, :flat]

  use SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases

  alias Commanded.Aggregate.Multi
  alias SegmentChallenge.Leaderboards.ChallengeLeaderboard
  alias SegmentChallenge.Leaderboards.ChallengeLeaderboard.LeaderboardEntry

  def stage_types, do: @stage_types

  @doc """
  Create a leaderboard for a challenge.
  """
  def execute(%ChallengeLeaderboard{}, %CreateChallengeLeaderboard{} = command) do
    %CreateChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      gender: gender,
      rank_by: rank_by,
      rank_order: rank_order,
      points: points,
      has_goal: has_goal?
    } = command

    %ChallengeLeaderboardCreated{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      gender: gender,
      rank_by: rank_by,
      rank_order: rank_order,
      points: points,
      has_goal?: has_goal?
    }
  end

  @doc """
  Remove the competitor from the challenge leaderboard and update any affected rankings
  """
  def execute(
        %ChallengeLeaderboard{} = cl,
        %RemoveCompetitorFromChallengeLeaderboard{} = command
      ) do
    %RemoveCompetitorFromChallengeLeaderboard{athlete_uuid: athlete_uuid} = command

    cl
    |> Multi.new()
    |> Multi.execute(&remove_competitor(&1, athlete_uuid))
    |> Multi.execute(&rank_challenge_leaderboard/1)
  end

  @doc """
  Assign points to each competitor based upon their rank in the stage
  """
  def execute(
        %ChallengeLeaderboard{finalised?: false} = cl,
        %AssignPointsFromStageLeaderboard{} = command
      ) do
    %AssignPointsFromStageLeaderboard{
      stage_uuid: stage_uuid,
      challenge_stage_uuids: stage_uuids,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      entries: entries
    } = command

    cl
    |> Multi.new()
    |> Multi.execute(
      &assign_points_from_stage_leaderboard(
        &1,
        stage_uuid,
        stage_type,
        points_adjustment,
        entries
      )
    )
    |> Multi.execute(&rank_challenge_leaderboard/1)
    |> Multi.execute(&goal_assignment(&1, stage_uuids))
  end

  def execute(%ChallengeLeaderboard{finalised?: true}, %AssignPointsFromStageLeaderboard{}) do
    {:error, :challenge_leaderboard_has_been_finalised}
  end

  @doc """
  Adjust the points assignment from a stage rank.
  """
  def execute(%ChallengeLeaderboard{} = cl, %AdjustPointsFromStageLeaderboard{} = adjust_points) do
    %AdjustPointsFromStageLeaderboard{
      challenge_stage_uuids: stage_uuids,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      adjusted_entries: adjusted_entries
    } = adjust_points

    cl
    |> Multi.new()
    |> Multi.execute(&adjust_points_from_previous_entries(&1, adjust_points))
    |> Multi.execute(&remove_zero_rated_entries/1)
    |> Multi.execute(&rank_challenge_leaderboard/1)
    |> Multi.execute(
      &assign_points_from_stage_leaderboard(
        &1,
        stage_uuid,
        stage_type,
        points_adjustment,
        adjusted_entries
      )
    )
    |> Multi.execute(&rank_challenge_leaderboard/1)
    |> Multi.execute(&goal_assignment(&1, stage_uuids))
  end

  @doc """
  Adjust an athlete's points in the leaderboard.
  """
  def execute(
        %ChallengeLeaderboard{} = cl,
        %AdjustAthletePointsInChallengeLeaderboard{} = adjust_points
      ) do
    cl
    |> Multi.new()
    |> Multi.execute(&do_adjust_athlete_points(&1, adjust_points))
    |> Multi.execute(&remove_zero_rated_entries/1)
    |> Multi.execute(&rank_challenge_leaderboard/1)
  end

  @doc """
  Remove an unwanted challenge leaderboard
  """
  def execute(
        %ChallengeLeaderboard{
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          removed?: false
        },
        %RemoveChallengeLeaderboard{}
      ) do
    %ChallengeLeaderboardRemoved{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid
    }
  end

  def execute(
        %ChallengeLeaderboard{removed?: true},
        %RemoveChallengeLeaderboard{}
      ) do
    {:error, :challenge_leaderboard_has_already_been_removed}
  end

  def execute(
        %ChallengeLeaderboard{challenge_leaderboard_uuid: challenge_leaderboard_uuid},
        %ReconfigureChallengeLeaderboardPoints{points: points}
      ) do
    %ChallengeLeaderboardPointsReconfigured{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      points: points
    }
  end

  @doc """
  Produce the final leaderboard for the challenge
  """
  def execute(
        %ChallengeLeaderboard{finalised?: true},
        %FinaliseChallengeLeaderboard{}
      ) do
    {:error, :challenge_leaderboard_has_been_finalised}
  end

  def execute(%ChallengeLeaderboard{finalised?: false} = cl, %FinaliseChallengeLeaderboard{}) do
    %ChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      entries: entries,
      rank_by: rank_by,
      rank_order: rank_order
    } = cl

    final_entries =
      entries
      |> Map.values()
      |> sort_by(rank_by, rank_order)
      |> Enum.map(
        &Map.take(&1, [
          :rank,
          :athlete_uuid,
          :gender,
          :points,
          :goals,
          :elapsed_time_in_seconds,
          :moving_time_in_seconds,
          :distance_in_metres,
          :elevation_gain_in_metres
        ])
      )

    %ChallengeLeaderboardFinalised{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      entries: final_entries
    }
  end

  @doc """
  Allow a previously limited competitor to score points from their stage leaderboard placing.
  """
  def execute(
        %ChallengeLeaderboard{} = cl,
        %AllowCompetitorPointScoringInChallengeLeaderboard{} = command
      ) do
    %ChallengeLeaderboard{challenge_leaderboard_uuid: challenge_leaderboard_uuid} = cl
    %AllowCompetitorPointScoringInChallengeLeaderboard{athlete_uuid: athlete_uuid} = command

    %CompetitorScoringInChallengeLeaderboardAllowed{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      athlete_uuid: athlete_uuid
    }
  end

  @doc """
  Prevent a competitor from scoring points from their stage leaderboard placing
  """
  def execute(
        %ChallengeLeaderboard{} = cl,
        %LimitCompetitorPointScoringInChallengeLeaderboard{} = command
      ) do
    %ChallengeLeaderboard{challenge_leaderboard_uuid: challenge_leaderboard_uuid} = cl

    %LimitCompetitorPointScoringInChallengeLeaderboard{athlete_uuid: athlete_uuid, reason: reason} =
      command

    %CompetitorScoringInChallengeLeaderboardLimited{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      athlete_uuid: athlete_uuid,
      reason: reason
    }
  end

  # State mutators

  def apply(%ChallengeLeaderboard{} = cl, %ChallengeLeaderboardCreated{} = event) do
    %ChallengeLeaderboardCreated{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      gender: gender,
      rank_by: rank_by,
      rank_order: rank_order,
      points: points,
      has_goal?: has_goal?
    } = event

    %ChallengeLeaderboard{
      cl
      | challenge_leaderboard_uuid: challenge_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        challenge_type: challenge_type,
        name: name,
        description: description,
        gender: gender,
        rank_by: String.to_atom(rank_by),
        rank_order: String.to_atom(rank_order),
        points: points,
        has_goal?: has_goal?
    }
  end

  def apply(
        %ChallengeLeaderboard{} = cl,
        %AthleteAccumulatedActivityInChallengeLeaderboard{} = event
      ) do
    %ChallengeLeaderboard{entries: entries} = cl

    %AthleteAccumulatedActivityInChallengeLeaderboard{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid,
      gender: gender,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      goals: goals
    } = event

    entry =
      case leaderboard_entry_for_athlete(cl, athlete_uuid) do
        nil ->
          # Add new entry
          %LeaderboardEntry{
            athlete_uuid: athlete_uuid,
            gender: gender,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            moving_time_in_seconds: moving_time_in_seconds,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            goals: goals
          }

        %LeaderboardEntry{} = entry ->
          # Adjust existing entry
          entry
          |> LeaderboardEntry.adjust(:elapsed_time_in_seconds, elapsed_time_in_seconds)
          |> LeaderboardEntry.adjust(:moving_time_in_seconds, moving_time_in_seconds)
          |> LeaderboardEntry.adjust(:distance_in_metres, distance_in_metres)
          |> LeaderboardEntry.adjust(:elevation_gain_in_metres, elevation_gain_in_metres)
          |> LeaderboardEntry.adjust(:goals, goals)
      end
      |> LeaderboardEntry.record_stage_goal(goals, stage_uuid)

    %ChallengeLeaderboard{cl | entries: Map.put(entries, athlete_uuid, entry)}
  end

  def apply(
        %ChallengeLeaderboard{} = cl,
        %AthleteAccumulatedPointsInChallengeLeaderboard{} = event
      ) do
    %ChallengeLeaderboard{entries: entries} = cl

    %AthleteAccumulatedPointsInChallengeLeaderboard{
      athlete_uuid: athlete_uuid,
      gender: gender,
      points: points
    } = event

    entry =
      case leaderboard_entry_for_athlete(cl, athlete_uuid) do
        nil ->
          # Add new entry
          %LeaderboardEntry{
            athlete_uuid: athlete_uuid,
            gender: gender,
            points: points
          }

        %LeaderboardEntry{} = entry ->
          # Adjust existing entry
          LeaderboardEntry.adjust(entry, :points, points)
      end

    %ChallengeLeaderboard{cl | entries: Map.put(entries, athlete_uuid, entry)}
  end

  def apply(
        %ChallengeLeaderboard{} = cl,
        %AthleteActivityAdjustedInChallengeLeaderboard{} = event
      ) do
    %ChallengeLeaderboard{entries: entries} = cl

    %AthleteActivityAdjustedInChallengeLeaderboard{
      athlete_uuid: athlete_uuid,
      elapsed_time_in_seconds_adjustment: elapsed_time_in_seconds,
      moving_time_in_seconds_adjustment: moving_time_in_seconds,
      distance_in_metres_adjustment: distance_in_metres,
      elevation_gain_in_metres_adjustment: elevation_gain_in_metres,
      goals_adjustment: goals
    } = event

    entries =
      update_leaderboard_entry(entries, athlete_uuid, fn %LeaderboardEntry{} = entry ->
        entry
        |> LeaderboardEntry.adjust(:elapsed_time_in_seconds, elapsed_time_in_seconds)
        |> LeaderboardEntry.adjust(:moving_time_in_seconds, moving_time_in_seconds)
        |> LeaderboardEntry.adjust(:distance_in_metres, distance_in_metres)
        |> LeaderboardEntry.adjust(:elevation_gain_in_metres, elevation_gain_in_metres)
        |> LeaderboardEntry.adjust(:goals, goals)
      end)

    %ChallengeLeaderboard{cl | entries: entries}
  end

  def apply(%ChallengeLeaderboard{} = cl, %AthletePointsAdjustedInChallengeLeaderboard{} = event) do
    %ChallengeLeaderboard{entries: entries} = cl

    %AthletePointsAdjustedInChallengeLeaderboard{
      athlete_uuid: athlete_uuid,
      points_adjustment: points_adjustment
    } = event

    entries =
      update_leaderboard_entry(entries, athlete_uuid, fn %LeaderboardEntry{} = entry ->
        LeaderboardEntry.adjust(entry, :points, points_adjustment)
      end)

    %ChallengeLeaderboard{cl | entries: entries}
  end

  def apply(%ChallengeLeaderboard{} = cl, %ChallengeLeaderboardRanked{} = event) do
    alias ChallengeLeaderboardRanked.Ranking

    %ChallengeLeaderboard{entries: entries} = cl

    %ChallengeLeaderboardRanked{
      new_entries: new_entries,
      positions_gained: positions_gained,
      positions_lost: positions_lost
    } = event

    changes = new_entries ++ positions_gained ++ positions_lost

    entries =
      Enum.reduce(changes, entries, fn %Ranking{} = change, entries ->
        %Ranking{rank: rank, athlete_uuid: athlete_uuid} = change

        update_leaderboard_entry(entries, athlete_uuid, fn %LeaderboardEntry{} = entry ->
          %LeaderboardEntry{entry | rank: rank}
        end)
      end)

    %ChallengeLeaderboard{cl | entries: entries}
  end

  def apply(%ChallengeLeaderboard{} = cl, %AthleteAchievedChallengeGoal{} = event) do
    %ChallengeLeaderboard{goal_achievers: goal_achievers} = cl
    %AthleteAchievedChallengeGoal{athlete_uuid: athlete_uuid} = event

    %ChallengeLeaderboard{cl | goal_achievers: MapSet.put(goal_achievers, athlete_uuid)}
  end

  def apply(%ChallengeLeaderboard{} = cl, %AthleteRemovedFromChallengeLeaderboard{} = event) do
    %ChallengeLeaderboard{entries: entries} = cl
    %AthleteRemovedFromChallengeLeaderboard{athlete_uuid: athlete_uuid} = event

    %ChallengeLeaderboard{cl | entries: Map.delete(entries, athlete_uuid)}
  end

  def apply(%ChallengeLeaderboard{} = cl, %ChallengeLeaderboardFinalised{}) do
    %ChallengeLeaderboard{cl | finalised?: true}
  end

  def apply(%ChallengeLeaderboard{} = cl, %ChallengeLeaderboardRemoved{}) do
    %ChallengeLeaderboard{cl | removed?: true}
  end

  def apply(%ChallengeLeaderboard{} = cl, %ChallengeLeaderboardPointsReconfigured{points: points}) do
    %ChallengeLeaderboard{cl | points: points}
  end

  def apply(
        %ChallengeLeaderboard{} = cl,
        %CompetitorScoringInChallengeLeaderboardLimited{} = event
      ) do
    %ChallengeLeaderboard{limited_competitors: limited_competitors} = cl
    %CompetitorScoringInChallengeLeaderboardLimited{athlete_uuid: athlete_uuid} = event

    %ChallengeLeaderboard{cl | limited_competitors: MapSet.put(limited_competitors, athlete_uuid)}
  end

  def apply(
        %ChallengeLeaderboard{} = cl,
        %CompetitorScoringInChallengeLeaderboardAllowed{} = event
      ) do
    %ChallengeLeaderboard{limited_competitors: limited_competitors} = cl
    %CompetitorScoringInChallengeLeaderboardAllowed{athlete_uuid: athlete_uuid} = event

    %ChallengeLeaderboard{
      cl
      | limited_competitors: MapSet.delete(limited_competitors, athlete_uuid)
    }
  end

  # Private helpers

  defp update_leaderboard_entry(entries, athlete_uuid, update_fn)
       when is_function(update_fn, 1) do
    case Map.get(entries, athlete_uuid) do
      nil ->
        entries

      %LeaderboardEntry{} = entry ->
        Map.put(entries, athlete_uuid, update_fn.(entry))
    end
  end

  defp leaderboard_entry_for_athlete(%ChallengeLeaderboard{} = cl, athlete_uuid) do
    %ChallengeLeaderboard{entries: entries} = cl

    Map.get(entries, athlete_uuid)
  end

  defp remove_competitor(%ChallengeLeaderboard{} = cl, athlete_uuid) do
    %ChallengeLeaderboard{challenge_leaderboard_uuid: challenge_leaderboard_uuid} = cl

    case leaderboard_entry_for_athlete(cl, athlete_uuid) do
      %LeaderboardEntry{rank: rank} ->
        %AthleteRemovedFromChallengeLeaderboard{
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          athlete_uuid: athlete_uuid,
          rank: rank
        }

      nil ->
        []
    end
  end

  defp assign_points_from_stage_leaderboard(
         %ChallengeLeaderboard{} = cl,
         stage_uuid,
         stage_type,
         points_adjustment,
         stage_leaderboard_entries
       ) do
    %ChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      gender: gender
    } = cl

    cl
    |> calculate_score(stage_type, points_adjustment, stage_leaderboard_entries)
    |> Enum.map(fn
      {:points, athlete_uuid, points} ->
        %AthleteAccumulatedPointsInChallengeLeaderboard{
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          challenge_type: challenge_type,
          athlete_uuid: athlete_uuid,
          gender: gender,
          points: points
        }

      {:activity, athlete_uuid, activity} ->
        %{
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres,
          stage_effort_count: stage_effort_count
        } = activity

        %AthleteAccumulatedActivityInChallengeLeaderboard{
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          challenge_type: challenge_type,
          stage_uuid: stage_uuid,
          athlete_uuid: athlete_uuid,
          gender: gender,
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres,
          goals: Map.get(activity, :goals),
          goal_progress: Map.get(activity, :goal_progress),
          activity_count: stage_effort_count
        }
    end)
  end

  defp calculate_score(
         %ChallengeLeaderboard{} = cl,
         stage_type,
         points_adjustment,
         stage_leaderboard_entries
       ) do
    case cl do
      %ChallengeLeaderboard{rank_by: :points} = cl ->
        calculate_points_from_rank(cl, stage_type, points_adjustment, stage_leaderboard_entries)

      %ChallengeLeaderboard{rank_by: rank_by}
      when rank_by in [
             :goals,
             :distance_in_metres,
             :elapsed_time_in_seconds,
             :elevation_gain_in_metres,
             :moving_time_in_seconds
           ] ->
        Enum.map(stage_leaderboard_entries, fn %{athlete_uuid: athlete_uuid} = entry ->
          {:activity, athlete_uuid, entry}
        end)
    end
  end

  defp calculate_points_from_rank(
         %ChallengeLeaderboard{} = cl,
         stage_type,
         points_adjustment,
         stage_leaderboard_entries
       ) do
    %ChallengeLeaderboard{points: points} = cl

    point_scoring =
      points
      |> adjust_points(points_adjustment)
      |> point_scoring_for_stage(stage_type)

    # Exclude competitors who have limited participation and cannot accumulate points.
    grouped_by_rank =
      stage_leaderboard_entries
      |> Enum.reject(fn %{athlete_uuid: athlete_uuid} ->
        is_limited_from_point_scoring?(cl, athlete_uuid)
      end)
      |> Enum.group_by(fn %{rank: rank} -> rank end)

    grouped_by_rank
    |> Map.keys()
    |> Enum.sort()
    |> Enum.flat_map_reduce(1, fn key, rank ->
      entries =
        grouped_by_rank
        |> Map.get(key)
        |> Enum.map(fn %{athlete_uuid: athlete_uuid} -> {rank, athlete_uuid} end)

      {entries, rank + 1}
    end)
    |> elem(0)
    |> Enum.reduce([], fn {rank, athlete_uuid}, acc ->
      case points_for_rank(point_scoring, rank) do
        0 ->
          acc

        points ->
          [{:points, athlete_uuid, points} | acc]
      end
    end)
    |> Enum.reverse()
  end

  # apply optional points adjustment to scoring
  defp adjust_points(points, adjustment)
  defp adjust_points(points, nil), do: points
  defp adjust_points(_points, "preview"), do: []
  defp adjust_points(points, "double") when is_list(points), do: double_points(points)

  defp adjust_points(points, "double") when is_map(points) do
    Enum.reduce(points, %{}, fn {key, value}, adjusted_points ->
      Map.put(adjusted_points, key, double_points(value))
    end)
  end

  defp adjust_points(points, "queen") when is_map(points) do
    case Map.get(points, :mountain, nil) do
      nil ->
        points

      mountain_points ->
        # queen stage has double mountain points
        Map.put(points, :mountain, double_points(mountain_points))
    end
  end

  defp adjust_points(points, _adjustment), do: points

  defp double_points(points), do: Enum.map(points, &(&1 * 2))

  # get the point scoring rules for the given stage type
  defp point_scoring_for_stage(points, stage_type)
  defp point_scoring_for_stage([], _stage_type), do: []
  defp point_scoring_for_stage(points, _stage_type) when is_list(points), do: points

  defp point_scoring_for_stage(points, stage_type)
       when is_map(points) and is_bitstring(stage_type),
       do: point_scoring_for_stage(points, String.to_atom(stage_type))

  defp point_scoring_for_stage(points, stage_type) when is_map(points) and is_atom(stage_type),
    do: Map.get(points, stage_type, [])

  # get the number of points for a given rank
  defp points_for_rank(point_scoring, rank)
  defp points_for_rank([], _rank), do: 0

  defp points_for_rank(point_scoring, rank) when is_list(point_scoring),
    do: Enum.at(point_scoring, rank - 1, 0)

  defp rank_challenge_leaderboard(%ChallengeLeaderboard{} = cl) do
    %ChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      entries: entries,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal?: has_goal?
    } = cl

    leaderboard_rank = %ChallengeLeaderboardRanked{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      has_goal?: has_goal?
    }

    entries
    |> apply_ranking(rank_by, rank_order)
    |> Enum.reduce(leaderboard_rank, fn {entry, new_rank}, leaderboard_rank ->
      %LeaderboardEntry{athlete_uuid: athlete_uuid, rank: rank} = entry

      ranking = %ChallengeLeaderboardRanked.Ranking{athlete_uuid: athlete_uuid, rank: new_rank}

      case rank do
        nil ->
          # New entry into leaderboard
          %ChallengeLeaderboardRanked{
            leaderboard_rank
            | new_entries: leaderboard_rank.new_entries ++ [ranking]
          }

        current_rank when new_rank < current_rank ->
          # Gained position
          ranking = %ChallengeLeaderboardRanked.Ranking{
            ranking
            | positions_changed: current_rank - new_rank
          }

          %ChallengeLeaderboardRanked{
            leaderboard_rank
            | positions_gained: leaderboard_rank.positions_gained ++ [ranking]
          }

        current_rank when new_rank > current_rank ->
          # Lost position
          ranking = %ChallengeLeaderboardRanked.Ranking{
            ranking
            | positions_changed: new_rank - current_rank
          }

          %ChallengeLeaderboardRanked{
            leaderboard_rank
            | positions_lost: leaderboard_rank.positions_lost ++ [ranking]
          }

        current_rank when new_rank == current_rank ->
          # Unchanged position
          leaderboard_rank
      end
    end)
    |> case do
      %ChallengeLeaderboardRanked{new_entries: [], positions_gained: [], positions_lost: []} -> []
      leaderboard_rank -> [leaderboard_rank]
    end
  end

  defp apply_ranking(entries, rank_by, rank_order) do
    entries
    |> Map.values()
    |> sort_by(rank_by, rank_order)
    |> Enum.flat_map_reduce({0, 0, 0}, fn entry, {rank, skipped, current_value} ->
      value = Map.get(entry, rank_by)

      {rank, skipped} =
        case value do
          ^current_value -> {rank, skipped + 1}
          _ -> {rank + skipped + 1, 0}
        end

      {[{entry, rank}], {rank, skipped, value}}
    end)
    |> elem(0)
  end

  defp sort_by(entries, field, direction)
  defp sort_by(entries, field, :asc), do: Enum.sort_by(entries, &Map.get(&1, field))
  defp sort_by(entries, field, :desc), do: Enum.sort_by(entries, &(-Map.get(&1, field)))

  # Adjust points assigned from previous entries in challenge leaderboard.
  defp adjust_points_from_previous_entries(
         %ChallengeLeaderboard{} = cl,
         %AdjustPointsFromStageLeaderboard{} = adjustment
       ) do
    %ChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      gender: gender
    } = cl

    %AdjustPointsFromStageLeaderboard{
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      previous_entries: previous_entries
    } = adjustment

    cl
    |> calculate_score(stage_type, points_adjustment, previous_entries)
    |> Enum.map(fn
      {:points, athlete_uuid, points} ->
        %AthletePointsAdjustedInChallengeLeaderboard{
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          athlete_uuid: athlete_uuid,
          gender: gender,
          points_adjustment: -points
        }

      {:activity, athlete_uuid, activity} ->
        %{
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres,
          stage_effort_count: stage_effort_count
        } = activity

        %AthleteActivityAdjustedInChallengeLeaderboard{
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          stage_uuid: stage_uuid,
          athlete_uuid: athlete_uuid,
          gender: gender,
          elapsed_time_in_seconds_adjustment: elapsed_time_in_seconds,
          moving_time_in_seconds_adjustment: moving_time_in_seconds,
          distance_in_metres_adjustment: distance_in_metres,
          elevation_gain_in_metres_adjustment: elevation_gain_in_metres,
          goals_adjustment: Map.get(activity, :goals),
          goal_progress_adjustment: Map.get(activity, :goal_progress),
          activity_count_adjustment: stage_effort_count
        }
    end)
  end

  defp do_adjust_athlete_points(
         %ChallengeLeaderboard{} = cl,
         %AdjustAthletePointsInChallengeLeaderboard{} = adjust_points
       ) do
    %ChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid
    } = cl

    %AdjustAthletePointsInChallengeLeaderboard{
      athlete_uuid: athlete_uuid,
      points_adjustment: points_adjustment
    } = adjust_points

    case leaderboard_entry_for_athlete(cl, athlete_uuid) do
      %LeaderboardEntry{} = entry ->
        %LeaderboardEntry{gender: gender} = entry

        %AthletePointsAdjustedInChallengeLeaderboard{
          challenge_leaderboard_uuid: challenge_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          athlete_uuid: athlete_uuid,
          gender: gender,
          points_adjustment: points_adjustment
        }

      nil ->
        []
    end
  end

  defp remove_zero_rated_entries(%ChallengeLeaderboard{} = cl) do
    %ChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      rank_by: rank_by,
      entries: entries
    } = cl

    entries
    |> Enum.filter(fn {_athlete_uuid, %LeaderboardEntry{} = entry} ->
      Map.get(entry, rank_by) <= 0
    end)
    |> Enum.map(fn {_athlete_uuid, %LeaderboardEntry{} = entry} ->
      %LeaderboardEntry{athlete_uuid: athlete_uuid, rank: rank} = entry

      %AthleteRemovedFromChallengeLeaderboard{
        challenge_leaderboard_uuid: challenge_leaderboard_uuid,
        athlete_uuid: athlete_uuid,
        rank: rank
      }
    end)
  end

  defp goal_assignment(%ChallengeLeaderboard{has_goal?: false}, _stage_uuids), do: []
  defp goal_assignment(%ChallengeLeaderboard{has_goal?: true}, []), do: []

  defp goal_assignment(%ChallengeLeaderboard{has_goal?: true} = cl, stage_uuids) do
    %ChallengeLeaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      entries: entries
    } = cl

    stage_uuids = MapSet.new(stage_uuids)

    entries
    |> Map.values()
    |> Enum.filter(&LeaderboardEntry.achieved_goal?(&1, stage_uuids))
    |> Enum.reject(fn %LeaderboardEntry{} = entry ->
      %LeaderboardEntry{athlete_uuid: athlete_uuid} = entry

      goal_achiever?(cl, athlete_uuid)
    end)
    |> Enum.map(fn %LeaderboardEntry{} = entry ->
      %LeaderboardEntry{athlete_uuid: athlete_uuid} = entry

      %AthleteAchievedChallengeGoal{
        challenge_leaderboard_uuid: challenge_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        athlete_uuid: athlete_uuid
      }
    end)
  end

  defp goal_achiever?(%ChallengeLeaderboard{} = cl, athlete_uuid) do
    %ChallengeLeaderboard{goal_achievers: goal_achievers} = cl

    MapSet.member?(goal_achievers, athlete_uuid)
  end

  defp is_limited_from_point_scoring?(%ChallengeLeaderboard{} = cl, athlete_uuid) do
    %ChallengeLeaderboard{limited_competitors: limited_competitors} = cl

    MapSet.member?(limited_competitors, athlete_uuid)
  end
end
