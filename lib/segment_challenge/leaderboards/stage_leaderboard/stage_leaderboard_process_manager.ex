defmodule SegmentChallenge.Leaderboards.StageLeaderboardProcessManager do
  @moduledoc """
  Create leaderboards for each stage and notify each leaderboard when a stage
  effort is recorded.
  """

  use Commanded.ProcessManagers.ProcessManager,
    name: "StageLeaderboardProcessManager",
    router: SegmentChallenge.Router

  import SegmentChallenge.Enumerable, only: [map_to_struct: 2, map_to_struct: 3]

  @derive Jason.Encoder
  defstruct [:challenge_uuid, :stage_uuid, leaderboards: [], stage_efforts: []]

  defmodule StageLeaderboardDetail do
    @derive Jason.Encoder
    defstruct [:stage_leaderboard_uuid]
  end

  alias SegmentChallenge.Events.{
    CompetitorRemovedFromStage,
    StageEffortFlagged,
    StageEffortRecorded,
    StageEffortRemoved,
    StageEffortsCleared,
    StageEnded,
    StageLeaderboardCreated,
    StageLeaderboardRequested,
    StageLeaderboardsApproved,
    StageStarted
  }

  alias SegmentChallenge.Commands.{
    CreateStageLeaderboard,
    FinaliseStageLeaderboard,
    RankStageEffortsInStageLeaderboard,
    ResetStageLeaderboard
  }

  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageEfforts
  alias SegmentChallenge.Leaderboards.StageLeaderboardProcessManager
  alias SegmentChallenge.Leaderboards.StageLeaderboardProcessManager.StageLeaderboardDetail

  def interested?(%StageStarted{stage_uuid: stage_uuid}), do: {:start, stage_uuid}
  def interested?(%StageLeaderboardRequested{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}
  def interested?(%StageLeaderboardCreated{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}
  def interested?(%StageEffortRecorded{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}
  def interested?(%StageEffortFlagged{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}
  def interested?(%StageEffortRemoved{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}
  def interested?(%StageEffortsCleared{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}

  def interested?(%CompetitorRemovedFromStage{stage_uuid: stage_uuid}),
    do: {:continue, stage_uuid}

  def interested?(%StageLeaderboardsApproved{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}
  def interested?(%StageEnded{stage_uuid: stage_uuid}), do: {:continue, stage_uuid}

  @doc """
  Create a requested leaderboard for a hosted challenge
  """
  def handle(%StageLeaderboardProcessManager{}, %StageLeaderboardRequested{} = event) do
    %StageLeaderboardRequested{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      name: name,
      gender: gender,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      rank_by: rank_by,
      rank_order: rank_order,
      accumulate_activities?: accumulate_activities,
      has_goal?: has_goal,
      goal_measure: goal_measure,
      goal: goal,
      goal_units: goal_units
    } = event

    %CreateStageLeaderboard{
      stage_leaderboard_uuid: UUID.uuid4(),
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      name: name,
      gender: gender,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      rank_by: rank_by,
      rank_order: rank_order,
      accumulate_activities: accumulate_activities,
      has_goal: has_goal,
      goal_measure: goal_measure,
      goal: goal,
      goal_units: goal_units
    }
  end

  # Ignore stage efforts for athlete's who have not specified their gender.
  def handle(%StageLeaderboardProcessManager{}, %StageEffortRecorded{athlete_gender: nil}), do: []

  def handle(%StageLeaderboardProcessManager{} = pm, %StageEffortRecorded{} = event),
    do: rank_stage_efforts(pm, event)

  def handle(%StageLeaderboardProcessManager{} = pm, %StageEffortFlagged{} = event),
    do: rank_stage_efforts(pm, event)

  def handle(%StageLeaderboardProcessManager{} = pm, %StageEffortRemoved{} = event),
    do: rank_stage_efforts(pm, event)

  def handle(%StageLeaderboardProcessManager{} = pm, %CompetitorRemovedFromStage{} = event),
    do: rank_stage_efforts(pm, event)

  def handle(%StageLeaderboardProcessManager{} = pm, %StageEffortsCleared{}) do
    %StageLeaderboardProcessManager{leaderboards: leaderboards} = pm

    Enum.map(leaderboards, fn leaderboard ->
      %ResetStageLeaderboard{stage_leaderboard_uuid: leaderboard.stage_leaderboard_uuid}
    end)
  end

  def handle(%StageLeaderboardProcessManager{} = pm, %StageLeaderboardsApproved{} = event),
    do: finalise_leaderboards(pm, event)

  def handle(%StageLeaderboardProcessManager{} = pm, %StageEnded{} = event),
    do: finalise_leaderboards(pm, event)

  ## State mutators

  def apply(%StageLeaderboardProcessManager{} = pm, %StageStarted{} = event) do
    %StageStarted{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = event

    %StageLeaderboardProcessManager{pm | challenge_uuid: challenge_uuid, stage_uuid: stage_uuid}
  end

  def apply(%StageLeaderboardProcessManager{} = pm, %StageLeaderboardCreated{} = event) do
    %StageLeaderboardProcessManager{leaderboards: leaderboards} = pm
    %StageLeaderboardCreated{stage_leaderboard_uuid: stage_leaderboard_uuid} = event

    leaderboard = %StageLeaderboardDetail{stage_leaderboard_uuid: stage_leaderboard_uuid}

    %StageLeaderboardProcessManager{pm | leaderboards: leaderboards ++ [leaderboard]}
  end

  def apply(%StageLeaderboardProcessManager{} = pm, %StageEffortRecorded{} = event) do
    %StageLeaderboardProcessManager{pm | stage_efforts: recorded_stage_efforts(pm, event)}
  end

  def apply(%StageLeaderboardProcessManager{} = pm, %StageEffortFlagged{} = event) do
    %StageLeaderboardProcessManager{pm | stage_efforts: recorded_stage_efforts(pm, event)}
  end

  def apply(%StageLeaderboardProcessManager{} = pm, %StageEffortRemoved{} = event) do
    %StageLeaderboardProcessManager{pm | stage_efforts: recorded_stage_efforts(pm, event)}
  end

  def apply(%StageLeaderboardProcessManager{} = pm, %CompetitorRemovedFromStage{} = event) do
    %StageLeaderboardProcessManager{pm | stage_efforts: recorded_stage_efforts(pm, event)}
  end

  def apply(%StageLeaderboardProcessManager{} = pm, %StageEffortsCleared{} = event) do
    %StageLeaderboardProcessManager{pm | stage_efforts: recorded_stage_efforts(pm, event)}
  end

  ## Private helpers

  defp rank_stage_efforts(%StageLeaderboardProcessManager{} = pm, event) do
    %StageLeaderboardProcessManager{leaderboards: leaderboards} = pm

    stage_efforts =
      pm
      |> recorded_stage_efforts(event)
      |> map_to_struct(RankStageEffortsInStageLeaderboard.StageEffort)
      |> Enum.reverse()

    Enum.map(leaderboards, fn leaderboard ->
      %RankStageEffortsInStageLeaderboard{
        stage_leaderboard_uuid: leaderboard.stage_leaderboard_uuid,
        stage_efforts: stage_efforts
      }
    end)
  end

  defp recorded_stage_efforts(%StageLeaderboardProcessManager{} = pm, event) do
    %StageLeaderboardProcessManager{stage_efforts: stage_efforts} = pm

    StageEfforts.accumulate_stage_effort(stage_efforts, event)
  end

  # Rank and then finalise stage leaderboards.
  defp finalise_leaderboards(%StageLeaderboardProcessManager{} = pm, event) do
    %StageLeaderboardProcessManager{leaderboards: leaderboards} = pm

    rank_stage_efforts(pm, event) ++
      Enum.map(leaderboards, fn leaderboard ->
        %FinaliseStageLeaderboard{stage_leaderboard_uuid: leaderboard.stage_leaderboard_uuid}
      end)
  end

  defimpl Commanded.Serialization.JsonDecoder do
    import SegmentChallenge.Enumerable, only: [map_to_struct: 2, map_to_struct: 3]

    def decode(%StageLeaderboardProcessManager{} = pm) do
      %StageLeaderboardProcessManager{leaderboards: leaderboards, stage_efforts: stage_efforts} =
        pm

      leaderboards = map_to_struct(leaderboards, StageLeaderboardDetail)

      stage_efforts =
        map_to_struct(
          stage_efforts,
          StageEffortRecorded,
          &Commanded.Serialization.JsonDecoder.decode/1
        )

      %StageLeaderboardProcessManager{
        pm
        | leaderboards: leaderboards,
          stage_efforts: stage_efforts
      }
    end
  end
end
