defmodule SegmentChallenge.Leaderboards.StageLeaderboard do
  @moduledoc """
  Stage leaderboards represent the ranking of athletes on a specific stage.
  """
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :name,
    :gender,
    :stage_type,
    :points_adjustment,
    :accumulate_activities?,
    :rank_by,
    :rank_order,
    :goal,
    :goal_measure,
    :goal_units,
    :last_ranked,
    # Goal in either metres or seconds dependent upon stage rank by
    :goal_in_units,
    has_goal?: false,
    athlete_rankings: %{},
    stage_efforts: [],
    adjustments: [],
    finalised?: false,
    final_entries: [],
    goal_achievers: MapSet.new()
  ]

  use SegmentChallenge.Leaderboards.StageLeaderboard.Aliases

  import SegmentChallenge.Enumerable, only: [map_to_struct: 2]

  alias Commanded.Aggregate.Multi
  alias SegmentChallenge.Leaderboards.StageLeaderboard
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageEffort

  @doc """
  Create a leaderboard for one stage in a challenge.
  """
  def execute(%StageLeaderboard{stage_leaderboard_uuid: nil}, %CreateStageLeaderboard{} = command) do
    %CreateStageLeaderboard{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      name: name,
      gender: gender,
      accumulate_activities: accumulate_activities?,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal: has_goal?,
      goal_measure: goal_measure,
      goal: goal,
      goal_units: goal_units
    } = command

    %StageLeaderboardCreated{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      name: name,
      gender: gender,
      accumulate_activities?: accumulate_activities?,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal?: has_goal?,
      goal_measure: goal_measure,
      goal: goal,
      goal_units: goal_units
    }
  end

  def execute(%StageLeaderboard{}, %CreateStageLeaderboard{}),
    do: {:error, :already_created}

  @doc """
  Rank all stage efforts in leaderboard.
  """
  def execute(
        %StageLeaderboard{finalised?: false} = leaderboard,
        %RankStageEffortsInStageLeaderboard{} = command
      ) do
    %StageLeaderboard{gender: gender} = leaderboard
    %RankStageEffortsInStageLeaderboard{stage_efforts: stage_efforts} = command

    best_stage_efforts =
      stage_efforts
      |> map_to_struct(StageEffort)
      |> Enum.filter(&StageEffort.is_gender?(&1, gender))
      |> Enum.group_by(fn %StageEffort{athlete_uuid: athlete_uuid} -> athlete_uuid end)
      |> Enum.map(fn {_athlete_uuid, stage_efforts} ->
        best_stage_effort(leaderboard, stage_efforts)
      end)
      |> Enum.map(fn %StageEffort{} = stage_effort ->
        %StageEffort{
          stage_effort
          | goal_progress: calculate_goal_progress(leaderboard, stage_effort)
        }
      end)

    leaderboard
    |> Multi.new()
    |> Multi.execute(&rank_stage_efforts(&1, best_stage_efforts))
    |> Multi.execute(&goal_assignment/1)
  end

  def execute(%StageLeaderboard{}, %RankStageEffortsInStageLeaderboard{}), do: []

  @doc """
  Reset the leaderboard by clearing out any stage efforts
  """
  def execute(
        %StageLeaderboard{finalised?: false} = stage_leaderboard,
        %ResetStageLeaderboard{}
      ) do
    %StageLeaderboard{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid
    } = stage_leaderboard

    %StageLeaderboardCleared{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid
    }
  end

  def execute(%StageLeaderboard{finalised?: true}, %ResetStageLeaderboard{}),
    do: {:error, :stage_leaderboard_has_been_finalised}

  def execute(
        %StageLeaderboard{finalised?: false} = leaderboard,
        %SetStageLeaderboardPointsAdjustment{} = command
      ) do
    %StageLeaderboard{stage_leaderboard_uuid: stage_leaderboard_uuid} = leaderboard
    %SetStageLeaderboardPointsAdjustment{points_adjustment: points_adjustment} = command

    %StageLeaderboardPointsAdjusted{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      points_adjustment: points_adjustment
    }
  end

  def execute(%StageLeaderboard{finalised?: true}, %SetStageLeaderboardPointsAdjustment{}),
    do: {:error, :stage_leaderboard_has_been_finalised}

  @doc """
  Produce the final leaderboard for the stage after it ends
  """
  def execute(
        %StageLeaderboard{finalised?: false} = stage_leaderboard,
        %FinaliseStageLeaderboard{}
      ) do
    stage_leaderboard
    |> Multi.new()
    |> Multi.execute(fn stage_leaderboard ->
      %StageLeaderboard{
        stage_leaderboard_uuid: stage_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        stage_type: stage_type,
        points_adjustment: points_adjustment,
        gender: gender,
        has_goal?: has_goal?
      } = stage_leaderboard

      final_entries = final_entries(stage_leaderboard)

      %StageLeaderboardFinalised{
        stage_leaderboard_uuid: stage_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        stage_type: stage_type,
        points_adjustment: points_adjustment,
        gender: gender,
        has_goal?: has_goal?,
        entries: final_entries
      }
    end)
    |> Multi.execute(&goal_assignment/1)
  end

  def execute(%StageLeaderboard{finalised?: true}, %FinaliseStageLeaderboard{}), do: []

  @doc """
  Adjust the finalised leaderboard for the stage
  """
  def execute(%StageLeaderboard{finalised?: true, adjustments: []}, %AdjustStageLeaderboard{}),
    do: []

  def execute(%StageLeaderboard{finalised?: true}, %AdjustStageLeaderboard{}), do: []

  def execute(%StageLeaderboard{finalised?: false}, %AdjustStageLeaderboard{}),
    do: {:error, :stage_leaderboard_has_not_been_finalised}

  # State mutators

  def apply(%StageLeaderboard{} = stage_leaderboard, %StageLeaderboardCreated{} = event) do
    %StageLeaderboardCreated{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      name: name,
      gender: gender,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      accumulate_activities?: accumulate_activities?,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal?: has_goal?,
      goal_measure: goal_measure,
      goal: goal,
      goal_units: goal_units
    } = event

    stage_leaderboard = %StageLeaderboard{
      stage_leaderboard
      | stage_leaderboard_uuid: stage_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        name: name,
        gender: gender,
        stage_type: stage_type,
        points_adjustment: points_adjustment,
        accumulate_activities?: accumulate_activities?,
        rank_by: String.to_atom(rank_by),
        rank_order: String.to_atom(rank_order)
    }

    if has_goal? do
      goal_measure = goal_measure || rank_by

      goal_in_units =
        case goal_measure do
          distance when distance in ["distance_in_metres", "elevation_gain_in_metres"] ->
            # Convert goal to metres
            case goal_units do
              "metres" -> Decimal.from_float(goal)
              "kilometres" -> Decimal.mult(Decimal.from_float(goal), Decimal.new(1_000))
              "feet" -> Decimal.mult(Decimal.from_float(goal), Decimal.from_float(0.3048))
              "miles" -> Decimal.mult(Decimal.from_float(goal), Decimal.new(1609))
            end

          time when time in ["elapsed_time_in_seconds", "moving_time_in_seconds"] ->
            # Convert goal to seconds
            case goal_units do
              "seconds" -> Decimal.from_float(goal)
              "minutes" -> Decimal.mult(Decimal.from_float(goal), Decimal.new(60))
              "hours" -> Decimal.mult(Decimal.from_float(goal), Decimal.new(3_600))
              "days" -> Decimal.mult(Decimal.from_float(goal), Decimal.new(86_400))
            end
        end

      %StageLeaderboard{
        stage_leaderboard
        | has_goal?: true,
          goal: goal,
          goal_measure: String.to_atom(goal_measure),
          goal_units: goal_units,
          goal_in_units: goal_in_units
      }
    else
      %StageLeaderboard{stage_leaderboard | has_goal?: false}
    end
  end

  def apply(%StageLeaderboard{} = stage_leaderboard, %AthleteRankedInStageLeaderboard{} = event) do
    %StageLeaderboard{athlete_rankings: athlete_rankings} = stage_leaderboard
    %AthleteRankedInStageLeaderboard{athlete_uuid: athlete_uuid, rank: rank} = event

    %StageLeaderboard{
      stage_leaderboard
      | athlete_rankings: Map.put(athlete_rankings, athlete_uuid, rank)
    }
  end

  def apply(
        %StageLeaderboard{} = stage_leaderboard,
        %AthleteRemovedFromStageLeaderboard{} = event
      ) do
    %StageLeaderboard{athlete_rankings: athlete_rankings} = stage_leaderboard
    %AthleteRemovedFromStageLeaderboard{athlete_uuid: athlete_uuid} = event

    %StageLeaderboard{
      stage_leaderboard
      | athlete_rankings: Map.delete(athlete_rankings, athlete_uuid)
    }
  end

  def apply(
        %StageLeaderboard{} = stage_leaderboard,
        %StageLeaderboardRanked{stage_efforts: nil} = event
      ) do
    %StageLeaderboard{athlete_rankings: athlete_rankings} = stage_leaderboard

    %StageLeaderboardRanked{positions_gained: positions_gained, positions_lost: positions_lost} =
      event

    athlete_rankings =
      Enum.reduce(positions_gained ++ positions_lost, athlete_rankings, fn change, acc ->
        %{athlete_uuid: athlete_uuid, rank: rank} = change

        Map.put(acc, athlete_uuid, rank)
      end)

    %StageLeaderboard{
      stage_leaderboard
      | athlete_rankings: athlete_rankings
    }
  end

  def apply(%StageLeaderboard{} = stage_leaderboard, %StageLeaderboardRanked{} = event) do
    %StageLeaderboardRanked{stage_efforts: stage_efforts} = event

    athlete_rankings =
      Enum.reduce(
        stage_efforts,
        %{},
        fn stage_effort, acc ->
          %StageLeaderboardRanked.StageEffort{athlete_uuid: athlete_uuid, rank: rank} =
            stage_effort

          Map.put(acc, athlete_uuid, rank)
        end
      )

    %StageLeaderboard{
      stage_leaderboard
      | athlete_rankings: athlete_rankings,
        last_ranked: stage_efforts,
        stage_efforts: map_to_struct(stage_efforts, StageEffort)
    }
  end

  def apply(
        %StageLeaderboard{adjustments: adjustments} = stage_leaderboard,
        %PendingAdjustmentInStageLeaderboard{} = event
      ) do
    stage_effort = struct(StageEffort, Map.from_struct(event))

    %StageLeaderboard{stage_leaderboard | adjustments: [stage_effort | adjustments]}
  end

  def apply(%StageLeaderboard{} = stage_leaderboard, %AthleteAchievedStageGoal{} = event) do
    %StageLeaderboard{goal_achievers: goal_achievers} = stage_leaderboard
    %AthleteAchievedStageGoal{athlete_uuid: athlete_uuid} = event

    %StageLeaderboard{
      stage_leaderboard
      | goal_achievers: MapSet.put(goal_achievers, athlete_uuid)
    }
  end

  def apply(
        %StageLeaderboard{} = stage_leaderboard,
        %StageLeaderboardPointsAdjusted{points_adjustment: points_adjustment}
      ) do
    %StageLeaderboard{stage_leaderboard | points_adjustment: points_adjustment}
  end

  def apply(%StageLeaderboard{} = stage_leaderboard, %StageLeaderboardFinalised{} = event) do
    %StageLeaderboardFinalised{entries: entries} = event

    %StageLeaderboard{stage_leaderboard | finalised?: true, final_entries: entries}
  end

  def apply(%StageLeaderboard{} = stage_leaderboard, %StageLeaderboardCleared{}) do
    %StageLeaderboard{
      stage_leaderboard
      | athlete_rankings: %{},
        adjustments: [],
        last_ranked: nil,
        final_entries: [],
        goal_achievers: MapSet.new()
    }
  end

  def apply(%StageLeaderboard{} = stage_leaderboard, %StageLeaderboardAdjusted{} = event) do
    %StageLeaderboardAdjusted{adjusted_entries: adjusted_entries} = event

    %StageLeaderboard{stage_leaderboard | adjustments: [], final_entries: adjusted_entries}
  end

  def apply(%StageLeaderboard{} = stage_leaderboard, _event), do: stage_leaderboard

  ## Private helpers

  defp best_stage_effort(%StageLeaderboard{} = leaderboard, stage_efforts) do
    %StageLeaderboard{
      accumulate_activities?: accumulate_activities?,
      rank_by: rank_by,
      rank_order: rank_order
    } = leaderboard

    stage_effort =
      if accumulate_activities? do
        StageEffort.accumulate(stage_efforts)
      else
        stage_efforts |> sort_by(rank_by, rank_order) |> hd()
      end

    %StageEffort{stage_effort | stage_effort_count: length(stage_efforts)}
  end

  defp rank_stage_efforts(%StageLeaderboard{} = leaderboard, stage_efforts) do
    %StageLeaderboard{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal?: has_goal?,
      last_ranked: last_ranked
    } = leaderboard

    stage_efforts
    |> sort_by(rank_by, rank_order)
    |> apply_ranking(rank_by)
    |> Enum.reduce({[], [], [], []}, fn %StageEffort{} = stage_effort,
                                        {stage_efforts, new, gained, lost} ->
      %StageEffort{rank: rank, athlete_uuid: athlete_uuid} = stage_effort

      case athlete_rank(leaderboard, athlete_uuid) do
        nil ->
          # Athlete new entry
          ranking = %StageLeaderboardRanked.Ranking{
            athlete_uuid: athlete_uuid,
            rank: rank,
            positions_changed: nil
          }

          {[stage_effort | stage_efforts], [ranking | new], gained, lost}

        current_rank when rank < current_rank ->
          # Athlete gained position
          ranking = %StageLeaderboardRanked.Ranking{
            athlete_uuid: athlete_uuid,
            rank: rank,
            positions_changed: current_rank - rank
          }

          {[stage_effort | stage_efforts], new, [ranking | gained], lost}

        # Athlete lost position
        current_rank when rank > current_rank ->
          ranking = %StageLeaderboardRanked.Ranking{
            athlete_uuid: athlete_uuid,
            rank: rank,
            positions_changed: rank - current_rank
          }

          {[stage_effort | stage_efforts], new, gained, [ranking | lost]}

        ^rank ->
          # Athlete position unchanged
          {[stage_effort | stage_efforts], new, gained, lost}
      end
    end)
    |> case do
      {stage_efforts, new_positions, positions_gained, positions_lost} ->
        stage_efforts =
          stage_efforts |> map_to_struct(StageLeaderboardRanked.StageEffort) |> Enum.reverse()

        case stage_efforts do
          ^last_ranked ->
            []

          stage_efforts ->
            %StageLeaderboardRanked{
              stage_leaderboard_uuid: stage_leaderboard_uuid,
              stage_uuid: stage_uuid,
              challenge_uuid: challenge_uuid,
              has_goal?: has_goal?,
              stage_efforts: stage_efforts,
              new_positions: Enum.reverse(new_positions),
              positions_gained: Enum.reverse(positions_gained),
              positions_lost: Enum.reverse(positions_lost)
            }
        end
    end
  end

  defp athlete_rank(%StageLeaderboard{} = leaderboard, athlete_uuid) do
    %StageLeaderboard{athlete_rankings: athlete_rankings} = leaderboard

    Map.get(athlete_rankings, athlete_uuid)
  end

  defp calculate_goal_progress(
         %StageLeaderboard{has_goal?: true} = stage_leaderboard,
         %StageEffort{} = stage_effort
       ) do
    %StageLeaderboard{goal_measure: goal_measure, goal_in_units: goal_in_units} =
      stage_leaderboard

    value_in_units =
      case Map.get(stage_effort, goal_measure) do
        number when is_integer(number) -> Decimal.new(number)
        number when is_float(number) -> Decimal.from_float(number)
        nil -> Decimal.new(0)
      end

    Decimal.div(value_in_units, goal_in_units) |> Decimal.mult(Decimal.new(100))
  end

  defp calculate_goal_progress(%StageLeaderboard{}, %StageEffort{}), do: nil

  defp apply_ranking(stage_efforts, rank_by) do
    stage_efforts
    |> Enum.flat_map_reduce({0, 0, 0}, fn stage_effort, {rank, skipped, rank_value} ->
      value = Map.get(stage_effort, rank_by)

      {rank, skipped} =
        case value do
          ^rank_value -> {rank, skipped + 1}
          _value -> {rank + skipped + 1, 0}
        end

      {[%StageEffort{stage_effort | rank: rank}], {rank, skipped, value}}
    end)
    |> elem(0)
  end

  defp final_entries(%StageLeaderboard{} = stage_leaderboard) do
    %StageLeaderboard{
      stage_efforts: stage_efforts,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal?: has_goal?,
      goal_measure: goal_measure,
      goal_in_units: goal_in_units
    } = stage_leaderboard

    stage_efforts
    |> sort_by(rank_by, rank_order)
    |> apply_ranking(rank_by)
    |> Enum.map(fn %StageEffort{} = stage_effort ->
      %StageEffort{
        rank: rank,
        athlete_uuid: athlete_uuid,
        elapsed_time_in_seconds: elapsed_time_in_seconds,
        moving_time_in_seconds: moving_time_in_seconds,
        distance_in_metres: distance_in_metres,
        elevation_gain_in_metres: elevation_gain_in_metres,
        stage_effort_count: stage_effort_count
      } = stage_effort

      final_entry = %{
        rank: rank,
        athlete_uuid: athlete_uuid,
        elapsed_time_in_seconds: elapsed_time_in_seconds,
        moving_time_in_seconds: moving_time_in_seconds,
        distance_in_metres: distance_in_metres,
        elevation_gain_in_metres: elevation_gain_in_metres,
        stage_effort_count: stage_effort_count
      }

      if has_goal? do
        goals =
          case StageEffort.achieved_goal?(stage_effort, goal_measure, goal_in_units) do
            true -> 1
            false -> 0
          end

        goal_progress = StageEffort.goal_progress(stage_effort, goal_measure, goal_in_units)

        final_entry
        |> Map.put(:goals, goals)
        |> Map.put(:goal_progress, goal_progress)
      else
        final_entry
      end
    end)
  end

  defp goal_achiever?(%StageLeaderboard{} = sl, athlete_uuid) do
    %StageLeaderboard{goal_achievers: goal_achievers} = sl

    MapSet.member?(goal_achievers, athlete_uuid)
  end

  defp sort_by(stage_efforts, field, :asc), do: Enum.sort_by(stage_efforts, &Map.get(&1, field))

  defp sort_by(stage_efforts, field, :desc),
    do: Enum.sort_by(stage_efforts, &(-Map.get(&1, field)))

  defp goal_assignment(%StageLeaderboard{has_goal?: true} = stage_leaderboard) do
    %StageLeaderboard{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      stage_efforts: stage_efforts,
      accumulate_activities?: accumulate_activities?,
      goal: goal,
      goal_measure: goal_measure,
      goal_units: goal_units,
      goal_in_units: goal_in_units
    } = stage_leaderboard

    stage_efforts
    |> Enum.filter(&StageEffort.achieved_goal?(&1, goal_measure, goal_in_units))
    |> Enum.reject(fn %StageEffort{} = entry ->
      %StageEffort{athlete_uuid: athlete_uuid} = entry

      goal_achiever?(stage_leaderboard, athlete_uuid)
    end)
    |> Enum.map(fn %StageEffort{} = entry ->
      %StageEffort{
        athlete_uuid: athlete_uuid,
        strava_activity_id: strava_activity_id,
        strava_segment_effort_id: strava_segment_effort_id
      } = entry

      %AthleteAchievedStageGoal{
        stage_leaderboard_uuid: stage_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        stage_type: stage_type,
        athlete_uuid: athlete_uuid,
        strava_activity_id: strava_activity_id,
        strava_segment_effort_id: strava_segment_effort_id,
        goal: goal,
        goal_units: goal_units,
        single_activity_goal?: !accumulate_activities?
      }
    end)
  end

  defp goal_assignment(%StageLeaderboard{has_goal?: false}), do: []
end
