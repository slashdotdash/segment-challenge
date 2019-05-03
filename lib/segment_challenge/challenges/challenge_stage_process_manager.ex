defmodule SegmentChallenge.Challenges.ChallengeStageProcessManager do
  @moduledoc """
  Track the stages that comprise a challenge.
  """

  use Commanded.ProcessManagers.ProcessManager,
    name: "ChallengeStageProcessManager",
    router: SegmentChallenge.Router

  use SegmentChallenge.Challenges.Challenge.Aliases
  use SegmentChallenge.Stages.Stage.Aliases

  @derive Jason.Encoder
  defstruct [:challenge_uuid, cancelled?: false, stages: []]

  defmodule Stage do
    @derive Jason.Encoder
    defstruct [:stage_uuid, :stage_number, :name]
  end

  alias SegmentChallenge.Challenges.ChallengeStageProcessManager
  alias SegmentChallenge.Challenges.ChallengeStageProcessManager.Stage

  ## Process routing

  def interested?(%ChallengeCreated{challenge_uuid: challenge_uuid}),
    do: {:start, challenge_uuid}

  def interested?(%ChallengeStageRequested{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeStageStartRequested{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%StageCreated{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeIncludedActivitiesAdjusted{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%StageDeleted{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeCancelled{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  ## Event handling

  @doc """
  Create a requested stage for a challenge.
  """
  def handle(
        %ChallengeStageProcessManager{},
        %ChallengeStageRequested{stage_type: stage_type} = event
      )
      when stage_type in ["distance", "duration", "elevation"] do
    %ChallengeStageRequested{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      stage_type: stage_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      allow_private_activities?: allow_private_activities?,
      included_activity_types: included_activity_types,
      accumulate_activities?: accumulate_activities,
      has_goal?: has_goal?,
      goal: goal,
      goal_units: goal_units,
      visible?: visible?,
      created_by_athlete_uuid: created_by_athlete_uuid
    } = event

    %CreateActivityStage{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      stage_type: stage_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      allow_private_activities: allow_private_activities?,
      included_activity_types: included_activity_types,
      accumulate_activities: accumulate_activities,
      has_goal: has_goal?,
      goal: goal,
      goal_units: goal_units,
      visible: visible?,
      created_by_athlete_uuid: created_by_athlete_uuid
    }
  end

  def handle(
        %ChallengeStageProcessManager{},
        %ChallengeStageRequested{stage_type: "race"} = event
      ) do
    %ChallengeStageRequested{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      stage_type: stage_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      allow_private_activities?: allow_private_activities?,
      included_activity_types: included_activity_types,
      goal: goal,
      goal_units: goal_units,
      visible?: visible?,
      created_by_athlete_uuid: created_by_athlete_uuid
    } = event

    %CreateRaceStage{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      stage_type: stage_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      allow_private_activities: allow_private_activities?,
      included_activity_types: included_activity_types,
      goal: goal,
      goal_units: goal_units,
      visible: visible?,
      created_by_athlete_uuid: created_by_athlete_uuid
    }
  end

  def handle(%ChallengeStageProcessManager{}, %ChallengeStageStartRequested{} = event) do
    %ChallengeStageStartRequested{stage_uuid: stage_uuid} = event

    %StartStage{stage_uuid: stage_uuid}
  end

  @doc """
  Cancel all stages in the challenge when it has been cancelled
  """
  def handle(%ChallengeStageProcessManager{} = pm, %ChallengeCancelled{} = event) do
    %ChallengeStageProcessManager{challenge_uuid: challenge_uuid, stages: stages} = pm
    %ChallengeCancelled{cancelled_by_athlete_uuid: athlete_uuid} = event

    Enum.map(stages, fn stage ->
      %DeleteStage{
        stage_uuid: stage.stage_uuid,
        challenge_uuid: challenge_uuid,
        deleted_by_athlete_uuid: athlete_uuid
      }
    end)
  end

  def handle(%ChallengeStageProcessManager{} = pm, %StageCreated{} = event) do
    %ChallengeStageProcessManager{challenge_uuid: challenge_uuid} = pm

    %StageCreated{
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      name: name,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = event

    %IncludeStageInChallenge{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      name: name,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    }
  end

  def handle(%ChallengeStageProcessManager{} = pm, %ChallengeIncludedActivitiesAdjusted{} = event) do
    %ChallengeStageProcessManager{stages: stages} = pm
    %ChallengeIncludedActivitiesAdjusted{included_activity_types: included_activity_types} = event

    Enum.map(stages, fn stage ->
      %AdjustStageIncludedActivities{
        stage_uuid: stage.stage_uuid,
        included_activity_types: included_activity_types
      }
    end)
  end

  def handle(%ChallengeStageProcessManager{} = pm, %StageDeleted{} = event) do
    %ChallengeStageProcessManager{challenge_uuid: challenge_uuid} = pm
    %StageDeleted{stage_uuid: stage_uuid, stage_number: stage_number} = event

    %RemoveStageFromChallenge{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_number: stage_number
    }
  end

  ## Error handlers

  def error({:error, :stage_already_created}, _failed_command, _context) do
    {:skip, :continue_pending}
  end

  def error({:error, :cannot_delete_stage}, _failed_command, _context) do
    {:skip, :continue_pending}
  end

  def error({:error, :cannot_amend_stage}, _failed_command, _context) do
    {:skip, :continue_pending}
  end

  ## State mutators

  def apply(%ChallengeStageProcessManager{} = pm, %ChallengeCreated{} = event) do
    %ChallengeCreated{challenge_uuid: challenge_uuid} = event

    %ChallengeStageProcessManager{pm | challenge_uuid: challenge_uuid}
  end

  def apply(%ChallengeStageProcessManager{} = pm, %ChallengeCancelled{}) do
    %ChallengeStageProcessManager{pm | cancelled?: true}
  end

  def apply(%ChallengeStageProcessManager{} = pm, %StageCreated{} = event) do
    %ChallengeStageProcessManager{stages: stages} = pm

    %StageCreated{
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      name: name
    } = event

    stage = %Stage{
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      name: name
    }

    %ChallengeStageProcessManager{pm | stages: stages ++ [stage]}
  end

  def apply(%ChallengeStageProcessManager{} = pm, %StageDeleted{} = event) do
    %ChallengeStageProcessManager{stages: stages} = pm
    %StageDeleted{stage_uuid: stage_uuid} = event

    %ChallengeStageProcessManager{
      pm
      | stages: Enum.reject(stages, fn stage -> stage.stage_uuid == stage_uuid end)
    }
  end
end
