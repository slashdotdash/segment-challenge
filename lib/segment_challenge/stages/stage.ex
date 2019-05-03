defmodule SegmentChallenge.Stages.Stage do
  @moduledoc """
  A stage in a single or multi-stage challenge where athletes compete over a
  set time period (e.g. one month, one week).
  """

  @callback create(command :: struct()) :: list(events :: struct)
  @callback rank_by(String.t()) :: String.t()
  @callback rank_order(String.t()) :: String.t()
  @callback is_valid_stage_effort?(stage :: struct(), stage_effort :: struct()) :: true | false

  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :stage_type,
    :stage_module,
    :stage_number,
    :description,
    :strava_segment_id,
    :points_adjustment,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :accumulate_activities?,
    :goal,
    :goal_measure,
    :goal_units,
    # Goal in either metres or seconds dependent upon stage rank by
    :goal_in_units,
    :status,
    :stage_results,
    :total_elevation_gain,
    has_goal?: false,
    visible?: false,
    allow_private_activities?: false,
    included_activity_types: [],
    competitors: %{},
    stage_efforts: [],
    # List of Strava activity and segment effort ids of flagged segment efforts
    flagged_stage_efforts: MapSet.new()
  ]

  use SegmentChallenge.Stages.Stage.Aliases

  import SegmentChallenge.Stages.Stage.Guards

  alias Commanded.Aggregate.Multi
  alias SegmentChallenge.Stages.Competitor
  alias SegmentChallenge.Stages.Stage
  alias SegmentChallenge.Stages.Stage.ActivityStage
  alias SegmentChallenge.Stages.Stage.RaceStage
  alias SegmentChallenge.Stages.Stage.SegmentStage
  alias SegmentChallenge.Stages.Stage.StageEffort

  def execute(%Stage{status: nil}, %CreateActivityStage{} = command),
    do: ActivityStage.create(command)

  def execute(%Stage{}, %CreateActivityStage{}), do: {:error, :stage_already_created}

  def execute(%Stage{status: nil}, %CreateRaceStage{} = command),
    do: RaceStage.create(command)

  def execute(%Stage{}, %CreateRaceStage{}), do: {:error, :stage_already_created}

  def execute(%Stage{status: nil}, %CreateSegmentStage{} = command),
    do: SegmentStage.create(command)

  def execute(%Stage{}, %CreateSegmentStage{}), do: {:error, :stage_already_created}

  @doc """
  Make this stage the "preview stage" - no points are accumulated from the final stage leaderboard positions.
  """
  def execute(%Stage{status: status} = stage, %MakePreviewStage{}) when is_active_stage(status) do
    %Stage{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid} = stage

    %StageMadePreview{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid}
  end

  def execute(%Stage{}, %MakePreviewStage{}), do: {:error, :cannot_make_preview_stage}

  @doc """
  Make this stage the "queen stage" -- the hardest, most demanding and most
  prestigious stage of the challenge.
  """
  def execute(%Stage{status: status} = stage, %MakeQueenStage{}) when is_active_stage(status) do
    %Stage{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid} = stage

    %StageMadeQueen{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid}
  end

  def execute(%Stage{}, %MakeQueenStage{}), do: {:error, :cannot_make_queen_stage}

  @doc """
  Make this stage visible to everyone
  """
  def execute(%Stage{visible?: false} = stage, %RevealStage{}) do
    %Stage{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid} = stage

    %StageRevealed{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid}
  end

  def execute(%Stage{}, %RevealStage{}), do: []

  def execute(%Stage{description: description}, %SetStageDescription{description: description}),
    do: []

  def execute(%Stage{} = stage, %SetStageDescription{} = command) do
    %Stage{stage_uuid: stage_uuid} = stage

    %SetStageDescription{
      description: description,
      updated_by_athlete_uuid: updated_by_athlete_uuid
    } = command

    %StageDescriptionEdited{
      stage_uuid: stage_uuid,
      description: description,
      updated_by_athlete_uuid: updated_by_athlete_uuid
    }
  end

  @doc """
  Starting a stage in a challenge makes it the active stage
  """
  def execute(%Stage{status: :pending} = stage, %StartStage{}) do
    %Stage{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      start_date: start_date,
      start_date_local: start_date_local
    } = stage

    [
      %StageStarted{
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        stage_number: stage_number,
        start_date: start_date,
        start_date_local: start_date_local
      }
      | request_stage_leaderboards(stage)
    ]
  end

  def execute(%Stage{}, %StartStage{}), do: []

  def execute(%Stage{status: status} = stage, %IncludeCompetitorsInStage{} = command)
      when status in [:active, :ended] do
    %Stage{stage_uuid: stage_uuid} = stage
    %IncludeCompetitorsInStage{competitors: competitors} = command

    competitors
    |> Enum.reject(&is_stage_competitor?(stage, &1.athlete_uuid))
    |> Enum.map(&struct(CompetitorsJoinedStage.Competitor, Map.from_struct(&1)))
    |> case do
      [] ->
        nil

      joined ->
        %CompetitorsJoinedStage{stage_uuid: stage_uuid, competitors: joined}
    end
  end

  def execute(%Stage{}, %IncludeCompetitorsInStage{}), do: []

  def execute(%Stage{status: status} = stage, %RemoveCompetitorFromStage{} = command)
      when status in [:active, :ended] do
    %Stage{stage_uuid: stage_uuid, stage_efforts: stage_efforts} = stage
    %RemoveCompetitorFromStage{athlete_uuid: athlete_uuid, removed_at: removed_at} = command

    if is_stage_competitor?(stage, athlete_uuid) do
      attempt_count = StageEffort.count_by_athlete(stage_efforts, athlete_uuid)
      competitor_count = active_competitor_count(stage_efforts)

      %CompetitorRemovedFromStage{
        stage_uuid: stage_uuid,
        athlete_uuid: athlete_uuid,
        removed_at: removed_at,
        attempt_count: attempt_count,
        competitor_count: max(competitor_count - 1, 0)
      }
    else
      []
    end
  end

  def execute(%Stage{}, %RemoveCompetitorFromStage{}), do: []

  @doc """
  Configure a competitor's gender for an athlete with a previously undisclosed gender.

  Any of the athlete's existing stage efforts will be removed.
  """
  def execute(%Stage{status: :active} = stage, %ConfigureAthleteGenderInStage{} = command) do
    %ConfigureAthleteGenderInStage{athlete_uuid: athlete_uuid, gender: gender} = command

    if is_stage_competitor?(stage, athlete_uuid) do
      stage
      |> athlete_stage_efforts(athlete_uuid)
      |> Enum.reduce(Multi.new(stage), fn %StageEffort{} = stage_effort, multi ->
        Multi.execute(multi, &remove_stage_effort(&1, stage_effort))
      end)
      |> Multi.execute(fn %Stage{} ->
        %Stage{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = stage

        %AthleteGenderAmendedInStage{
          challenge_uuid: challenge_uuid,
          stage_uuid: stage_uuid,
          athlete_uuid: athlete_uuid,
          gender: gender
        }
      end)
    else
      []
    end
  end

  def execute(%Stage{}, %ConfigureAthleteGenderInStage{}), do: []

  @doc """
  Import the recorded efforts for the stage
  """
  def execute(%Stage{} = stage, %ImportStageEfforts{} = command) do
    %Stage{stage_module: stage_module} = stage
    %ImportStageEfforts{stage_efforts: stage_efforts} = command

    stage_efforts
    |> Stream.map(&struct(StageEffort, Map.from_struct(&1)))
    |> Stream.filter(&is_stage_competitor?(stage, &1.athlete_uuid))
    |> Stream.filter(&is_allowed_activity_type?(stage, &1))
    |> Stream.filter(&is_allowed_privacy?(stage, &1))
    |> Stream.filter(&stage_module.is_valid_stage_effort?(stage, &1))
    |> Stream.reject(&is_manual_entry?/1)
    |> Stream.reject(&is_recorded_stage_effort?(stage, &1))
    |> Stream.reject(&is_flagged_stage_effort?(stage, &1))
    |> Enum.reduce(Multi.new(stage), fn %StageEffort{} = stage_effort, multi ->
      Multi.execute(multi, &record_stage_effort(&1, stage_effort))
    end)
  end

  @doc """
  Flag a stage effort for a given reason. The effort will be permanently removed.
  """
  def execute(%Stage{status: :approved}, %FlagStageEffort{}), do: {:error, :stage_is_approved}

  def execute(%Stage{status: :deleted}, %FlagStageEffort{}), do: {:error, :stage_is_deleted}

  def execute(%Stage{} = stage, %FlagStageEffort{} = command) do
    %Stage{stage_uuid: stage_uuid, stage_efforts: stage_efforts} = stage

    %FlagStageEffort{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      flagged_by_athlete_uuid: flagged_by_athlete_uuid,
      reason: reason
    } = command

    case find_stage_effort(stage, strava_activity_id, strava_segment_effort_id) do
      {:ok, %StageEffort{} = stage_effort} ->
        %StageEffort{
          athlete_uuid: athlete_uuid,
          strava_activity_id: strava_activity_id,
          strava_segment_effort_id: strava_segment_effort_id,
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres
        } = stage_effort

        stage_effort_excluding_flagged = stage_efforts -- [stage_effort]

        attempt_count = StageEffort.count_by_athlete(stage_effort_excluding_flagged, athlete_uuid)
        competitor_count = active_competitor_count(stage_effort_excluding_flagged)

        %StageEffortFlagged{
          stage_uuid: stage_uuid,
          strava_activity_id: strava_activity_id,
          strava_segment_effort_id: strava_segment_effort_id,
          flagged_by_athlete_uuid: flagged_by_athlete_uuid,
          reason: reason,
          athlete_uuid: athlete_uuid,
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres,
          attempt_count: attempt_count,
          competitor_count: competitor_count
        }

      {:error, :not_found} ->
        []
    end
  end

  def execute(%Stage{} = stage, %RemoveStageActivity{} = event) do
    %Stage{stage_efforts: stage_efforts} = stage
    %RemoveStageActivity{strava_activity_id: strava_activity_id} = event

    activity_efforts =
      Enum.filter(stage_efforts, fn
        %StageEffort{strava_activity_id: ^strava_activity_id} -> true
        %StageEffort{} -> false
      end)

    stage
    |> Multi.new()
    |> Multi.reduce(activity_efforts, &remove_stage_effort/2)
  end

  @doc """
  Use a different Strava segment for this stage.

  For active stages, any recorded stage efforts are removed.
  Ignore when Strava segment is the same as current.
  """
  def execute(
        %Stage{strava_segment_id: strava_segment_id},
        %ChangeStageSegment{strava_segment_id: strava_segment_id}
      ),
      do: []

  def execute(%Stage{status: status} = stage, %ChangeStageSegment{} = command)
      when is_active_stage(status) do
    %Stage{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid} = stage
    %ChangeStageSegment{strava_segment_id: strava_segment_id} = command

    [
      %StageSegmentChanged{
        stage_uuid: stage_uuid,
        challenge_uuid: challenge_uuid,
        strava_segment_id: strava_segment_id
      }
      | clear_stage_efforts(stage)
    ]
  end

  def execute(%Stage{}, %ChangeStageSegment{}), do: {:error, :segment_cannot_be_amended}

  def execute(%Stage{} = stage, %AdjustStageDuration{} = command) do
    %Stage{stage_uuid: stage_uuid} = stage

    %AdjustStageDuration{
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = command

    %StageDurationAdjusted{
      stage_uuid: stage_uuid,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    }
  end

  def execute(%Stage{status: status} = stage, %AdjustStageIncludedActivities{} = command)
      when is_active_stage(status) do
    %Stage{included_activity_types: existing_activity_types} = stage
    %AdjustStageIncludedActivities{included_activity_types: included_activity_types} = command

    unless MapSet.equal?(MapSet.new(existing_activity_types), MapSet.new(included_activity_types)) do
      stage
      |> Multi.new()
      |> Multi.execute(&adjust_included_activities(&1, included_activity_types))
      |> Multi.execute(&remove_invalid_activity_types/1)
    else
      []
    end
  end

  def execute(%Stage{}, %AdjustStageIncludedActivities{}),
    do: {:error, :cannot_amend_stage}

  @doc """
  Ending a stage in a challenge makes it inactive
  """
  def execute(%Stage{stage_uuid: stage_uuid, status: :active} = stage, %EndStage{}) do
    %StageEnded{
      challenge_uuid: stage.challenge_uuid,
      stage_uuid: stage_uuid,
      stage_number: stage.stage_number,
      end_date: stage.end_date,
      end_date_local: stage.end_date_local
    }
  end

  def execute(%Stage{}, %EndStage{}), do: {:error, :stage_is_not_active}

  @doc """
  Approve the leaderboards for the stage once it has ended.

  This will finalise the stage leaderboards and use their rankings to assign
  points to the challenge leaderboards.
  """
  def execute(
        %Stage{status: :ended} = stage,
        %ApproveStageLeaderboards{} = command
      ) do
    %Stage{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid} = stage

    %ApproveStageLeaderboards{
      approved_by_athlete_uuid: approved_by_athlete_uuid,
      approved_by_club_uuid: approved_by_club_uuid,
      approval_message: approval_message
    } = command

    %StageLeaderboardsApproved{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      approved_by_athlete_uuid: approved_by_athlete_uuid,
      approved_by_club_uuid: approved_by_club_uuid,
      approval_message: approval_message
    }
  end

  def execute(%Stage{status: :approved}, %ApproveStageLeaderboards{}),
    do: {:error, :stage_already_approved}

  def execute(%Stage{}, %ApproveStageLeaderboards{}),
    do: {:error, :stage_has_not_ended}

  def execute(%Stage{status: status} = stage, %DeleteStage{} = command)
      when status in [:pending, :active, :ended] do
    %Stage{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number
    } = stage

    %DeleteStage{deleted_by_athlete_uuid: deleted_by_athlete_uuid} = command

    %StageDeleted{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      deleted_by_athlete_uuid: deleted_by_athlete_uuid
    }
  end

  def execute(%Stage{}, %DeleteStage{}), do: {:error, :cannot_delete_stage}

  def execute(
        %Stage{status: :ended, stage_results: stage_results},
        %PublishStageResults{message: stage_results}
      ),
      do: []

  def execute(%Stage{status: :ended} = stage, %PublishStageResults{} = command) do
    %Stage{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid} = stage

    %PublishStageResults{
      message: message,
      published_by_athlete_uuid: published_by_athlete_uuid,
      published_by_club_uuid: published_by_club_uuid
    } = command

    %StageResultsPublished{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      message: message,
      published_by_athlete_uuid: published_by_athlete_uuid,
      published_by_club_uuid: published_by_club_uuid
    }
  end

  def execute(%Stage{}, %PublishStageResults{}), do: {:error, :stage_has_not_ended}

  # State mutators

  def apply(%Stage{} = stage, %StageCreated{} = event) do
    %StageCreated{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      stage_type: stage_type,
      description: description,
      allow_private_activities?: allow_private_activities?,
      included_activity_types: included_activity_types,
      accumulate_activities?: accumulate_activities?,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      points_adjustment: points_adjustment,
      visible?: visible?
    } = event

    %Stage{
      stage
      | stage_uuid: stage_uuid,
        stage_module: stage_module(stage_type),
        status: :pending,
        challenge_uuid: challenge_uuid,
        stage_number: stage_number,
        stage_type: stage_type,
        description: description,
        allow_private_activities?: allow_private_activities?,
        included_activity_types: included_activity_types,
        accumulate_activities?: accumulate_activities?,
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local,
        points_adjustment: points_adjustment,
        visible?: visible?
    }
  end

  def apply(%Stage{} = stage, %StageSegmentConfigured{} = event) do
    %StageSegmentConfigured{
      strava_segment_id: strava_segment_id,
      total_elevation_gain: total_elevation_gain
    } = event

    %Stage{
      stage
      | strava_segment_id: strava_segment_id,
        total_elevation_gain: total_elevation_gain
    }
  end

  def apply(%Stage{} = stage, %StageGoalConfigured{} = event) do
    %Stage{stage_type: stage_type, stage_module: stage_module} = stage

    %StageGoalConfigured{
      goal_measure: goal_measure,
      goal: goal,
      goal_units: goal_units
    } = event

    goal_measure = goal_measure || stage_module.rank_by(stage_type)

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

    %Stage{
      stage
      | has_goal?: true,
        goal_measure: goal_measure,
        goal: goal,
        goal_units: goal_units,
        goal_in_units: goal_in_units
    }
  end

  def apply(%Stage{} = stage, %StageStarted{}) do
    %Stage{stage | status: :active, visible?: true}
  end

  def apply(%Stage{} = stage, %StageLeaderboardRequested{}), do: stage

  def apply(%Stage{} = stage, %CompetitorsJoinedStage{} = event) do
    %Stage{competitors: competitors} = stage
    %CompetitorsJoinedStage{competitors: joined_competitors} = event

    competitors =
      Enum.reduce(joined_competitors, competitors, fn joined_competitor, competitors ->
        Map.put(
          competitors,
          joined_competitor.athlete_uuid,
          struct(Competitor, Map.from_struct(joined_competitor))
        )
      end)

    %Stage{stage | competitors: competitors}
  end

  def apply(%Stage{} = stage, %CompetitorRemovedFromStage{} = event) do
    %Stage{competitors: competitors, stage_efforts: stage_efforts} = stage
    %CompetitorRemovedFromStage{athlete_uuid: athlete_uuid} = event

    %Stage{
      stage
      | competitors: Map.delete(competitors, athlete_uuid),
        stage_efforts:
          Enum.reject(stage_efforts, fn stage_effort ->
            stage_effort.athlete_uuid == athlete_uuid
          end)
    }
  end

  def apply(%Stage{} = stage, %AthleteGenderAmendedInStage{} = event) do
    %Stage{competitors: competitors} = stage
    %AthleteGenderAmendedInStage{athlete_uuid: athlete_uuid, gender: gender} = event

    competitors =
      Map.update(competitors, athlete_uuid, nil, fn competitor ->
        %Competitor{competitor | gender: gender}
      end)

    %Stage{stage | competitors: competitors}
  end

  def apply(%Stage{} = stage, %StageEffortRecorded{} = stage_effort_recorded) do
    %Stage{stage_efforts: stage_efforts} = stage

    stage_effort = struct(StageEffort, Map.from_struct(stage_effort_recorded))

    %Stage{stage | stage_efforts: [stage_effort | stage_efforts]}
  end

  def apply(%Stage{} = stage, %StageEffortRemoved{} = event) do
    %Stage{stage_efforts: stage_efforts} = stage

    %StageEffortRemoved{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = event

    stage_efforts =
      Enum.reject(
        stage_efforts,
        &is_stage_effort?(&1, strava_activity_id, strava_segment_effort_id)
      )

    %Stage{stage | stage_efforts: stage_efforts}
  end

  def apply(%Stage{} = stage, %StageEffortFlagged{} = event) do
    %Stage{stage_efforts: stage_efforts, flagged_stage_efforts: flagged_stage_efforts} = stage

    %StageEffortFlagged{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = event

    stage_efforts =
      Enum.reject(
        stage_efforts,
        &is_stage_effort?(&1, strava_activity_id, strava_segment_effort_id)
      )

    flagged_stage_efforts =
      MapSet.put(flagged_stage_efforts, {strava_activity_id, strava_segment_effort_id})

    %Stage{stage | stage_efforts: stage_efforts, flagged_stage_efforts: flagged_stage_efforts}
  end

  def apply(%Stage{} = stage, %StageDurationAdjusted{} = event) do
    %StageDurationAdjusted{
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = event

    %Stage{
      stage
      | start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local
    }
  end

  def apply(%Stage{} = stage, %StageIncludedActivitiesAdjusted{} = event) do
    %StageIncludedActivitiesAdjusted{included_activity_types: included_activity_types} = event

    %Stage{stage | included_activity_types: included_activity_types}
  end

  def apply(%Stage{} = stage, %StageSegmentChanged{} = event) do
    %StageSegmentChanged{strava_segment_id: strava_segment_id} = event

    %Stage{stage | strava_segment_id: strava_segment_id}
  end

  def apply(%Stage{} = stage, %StageEnded{}) do
    %Stage{stage | status: :ended}
  end

  def apply(%Stage{} = stage, %StageLeaderboardsApproved{}) do
    %Stage{stage | status: :approved}
  end

  def apply(%Stage{} = stage, %StageDeleted{}) do
    %Stage{stage | status: :deleted}
  end

  def apply(%Stage{} = stage, %StageMadePreview{}) do
    %Stage{stage | points_adjustment: "preview"}
  end

  def apply(%Stage{} = stage, %StageMadeQueen{}) do
    %Stage{stage | points_adjustment: "queen"}
  end

  def apply(%Stage{} = stage, %StageRevealed{}) do
    %Stage{stage | visible?: true}
  end

  def apply(%Stage{} = stage, %StageDescriptionEdited{} = event) do
    %StageDescriptionEdited{description: description} = event

    %Stage{stage | description: description}
  end

  def apply(%Stage{} = stage, %StageEffortsCleared{}) do
    %Stage{stage | stage_efforts: []}
  end

  def apply(%Stage{} = stage, %StageResultsPublished{} = event) do
    %StageResultsPublished{message: message} = event

    %Stage{stage | stage_results: message}
  end

  ## Private helpers

  # Is the given athlete a competitor in this stage?
  defp is_stage_competitor?(%Stage{} = stage, athlete_uuid) do
    %Stage{competitors: competitors} = stage

    Map.has_key?(competitors, athlete_uuid)
  end

  defp is_allowed_activity_type?(%Stage{} = stage, %StageEffort{trainer?: true} = stage_effort) do
    %Stage{included_activity_types: included_activity_types} = stage
    %StageEffort{activity_type: activity_type} = stage_effort

    # Allow trainer activities for stages that allow virtual rides, runs, and swims
    case activity_type do
      ride when ride in ["Ride", "VirtualRide"] ->
        Enum.member?(included_activity_types, "VirtualRide")

      run when run in ["Run", "VirtualRun"] ->
        Enum.member?(included_activity_types, "VirtualRun")

      indoor_activity
      when indoor_activity in [
             "Crossfit",
             "Elliptical",
             "IceSkate",
             "InlineSkate",
             "RockClimbing",
             "RollerSki",
             "Rowing",
             "Skateboard",
             "Soccer",
             "StairStepper",
             "Swim",
             "WeightTraining",
             "Workout",
             "Yoga"
           ] ->
        Enum.member?(included_activity_types, indoor_activity)

      _activity_type ->
        false
    end
  end

  defp is_allowed_activity_type?(%Stage{} = stage, %StageEffort{} = stage_effort) do
    %Stage{included_activity_types: included_activity_types} = stage
    %StageEffort{activity_type: activity_type} = stage_effort

    Enum.member?(included_activity_types, activity_type)
  end

  # Allow all public activities, but only allow private activities if configured.
  defp is_allowed_privacy?(%Stage{allow_private_activities?: true}, %StageEffort{}), do: true
  defp is_allowed_privacy?(%Stage{}, %StageEffort{private?: private?}), do: !private?

  # Was the activity created manually?
  defp is_manual_entry?(%StageEffort{manual?: manual?}), do: manual?

  defp is_recorded_stage_effort?(%Stage{} = stage, %StageEffort{} = stage_effort) do
    %Stage{stage_efforts: stage_efforts} = stage

    %StageEffort{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = stage_effort

    Enum.any?(stage_efforts, &is_stage_effort?(&1, strava_activity_id, strava_segment_effort_id))
  end

  defp is_stage_effort?(
         %StageEffort{
           strava_activity_id: strava_activity_id,
           strava_segment_effort_id: strava_segment_effort_id
         },
         strava_activity_id,
         strava_segment_effort_id
       ),
       do: true

  defp is_stage_effort?(%StageEffort{}, _strava_activity_id, _strava_segment_effort_id), do: false

  defp is_flagged_stage_effort?(%Stage{} = stage, %StageEffort{} = stage_effort) do
    %Stage{flagged_stage_efforts: flagged_stage_efforts} = stage

    %StageEffort{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = stage_effort

    MapSet.member?(flagged_stage_efforts, {strava_activity_id, strava_segment_effort_id})
  end

  defp athlete_stage_efforts(%Stage{} = stage, athlete_uuid) do
    %Stage{stage_efforts: stage_efforts} = stage

    Enum.filter(stage_efforts, &StageEffort.is_athlete?(&1, athlete_uuid))
  end

  defp find_stage_effort(%Stage{} = stage, strava_activity_id, strava_segment_effort_id) do
    %Stage{stage_efforts: stage_efforts} = stage

    case Enum.find(stage_efforts, fn
           %StageEffort{
             strava_activity_id: ^strava_activity_id,
             strava_segment_effort_id: ^strava_segment_effort_id
           } ->
             true

           %StageEffort{} ->
             false
         end) do
      %StageEffort{} = stage_effort -> {:ok, stage_effort}
      nil -> {:error, :not_found}
    end
  end

  defp record_stage_effort(%Stage{} = stage, %StageEffort{} = stage_effort) do
    %Stage{
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      competitors: competitors,
      stage_efforts: stage_efforts,
      total_elevation_gain: total_elevation_gain
    } = stage

    %StageEffort{
      athlete_uuid: athlete_uuid,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      start_date: start_date,
      start_date_local: start_date_local,
      trainer?: trainer?,
      commute?: commute?,
      manual?: manual?,
      private?: private?,
      flagged?: flagged?,
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts?: device_watts?,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate
    } = stage_effort

    %Competitor{gender: gender} = Map.get(competitors, athlete_uuid)

    attempt_count = StageEffort.count_by_athlete([stage_effort | stage_efforts], athlete_uuid)
    competitor_count = active_competitor_count([stage_effort | stage_efforts])

    %StageEffortRecorded{
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      athlete_uuid: athlete_uuid,
      athlete_gender: gender,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres || total_elevation_gain,
      start_date: start_date,
      start_date_local: start_date_local,
      trainer?: trainer?,
      commute?: commute?,
      manual?: manual?,
      private?: private?,
      flagged?: flagged?,
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts?: device_watts?,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate,
      attempt_count: attempt_count,
      competitor_count: competitor_count
    }
  end

  # Count competitors who have recorded a stage effort.
  defp active_competitor_count(stage_efforts) do
    stage_efforts
    |> Enum.reduce(MapSet.new(), fn %StageEffort{} = stage_effort, acc ->
      %StageEffort{athlete_uuid: athlete_uuid} = stage_effort

      MapSet.put(acc, athlete_uuid)
    end)
    |> MapSet.size()
  end

  defp remove_stage_effort(%Stage{} = stage, %StageEffort{} = stage_effort) do
    %Stage{stage_uuid: stage_uuid, stage_efforts: stage_efforts} = stage

    %StageEffort{
      athlete_uuid: athlete_uuid,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      start_date: start_date,
      start_date_local: start_date_local
    } = stage_effort

    stage_effort_excluding_removed = stage_efforts -- [stage_effort]

    attempt_count = StageEffort.count_by_athlete(stage_effort_excluding_removed, athlete_uuid)
    competitor_count = active_competitor_count(stage_effort_excluding_removed)

    %StageEffortRemoved{
      stage_uuid: stage_uuid,
      athlete_uuid: athlete_uuid,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      start_date: start_date,
      start_date_local: start_date_local,
      attempt_count: attempt_count,
      competitor_count: competitor_count
    }
  end

  defp clear_stage_efforts(%Stage{stage_efforts: []}), do: []

  defp clear_stage_efforts(%Stage{} = stage) do
    %Stage{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid} = stage

    [
      %StageEffortsCleared{stage_uuid: stage_uuid, challenge_uuid: challenge_uuid}
    ]
  end

  defp adjust_included_activities(%Stage{} = stage, included_activity_types) do
    %Stage{stage_uuid: stage_uuid} = stage

    %StageIncludedActivitiesAdjusted{
      stage_uuid: stage_uuid,
      included_activity_types: included_activity_types
    }
  end

  defp remove_invalid_activity_types(%Stage{} = stage) do
    %Stage{stage_efforts: stage_efforts} = stage

    {_stage, events} =
      stage_efforts
      |> Enum.reject(&is_allowed_activity_type?(stage, &1))
      |> Enum.reduce(Multi.new(stage), fn %StageEffort{} = stage_effort, multi ->
        Multi.execute(multi, &remove_stage_effort(&1, stage_effort))
      end)
      |> Multi.run()

    events
  end

  defp request_stage_leaderboards(%Stage{} = stage) do
    %Stage{
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      stage_module: stage_module,
      challenge_uuid: challenge_uuid,
      accumulate_activities?: accumulate_activities?,
      has_goal?: has_goal?,
      goal: goal,
      goal_measure: goal_measure,
      goal_units: goal_units
    } = stage

    rank_by = stage_module.rank_by(stage_type)
    rank_order = stage_module.rank_order(stage_type)

    [
      {"Men", "M"},
      {"Women", "F"}
    ]
    |> Enum.map(fn {name, gender} ->
      %StageLeaderboardRequested{
        stage_uuid: stage_uuid,
        stage_type: stage_type,
        challenge_uuid: challenge_uuid,
        name: name,
        gender: gender,
        rank_by: rank_by,
        rank_order: rank_order,
        accumulate_activities?: accumulate_activities?,
        has_goal?: has_goal?,
        goal: goal,
        goal_measure: goal_measure,
        goal_units: goal_units
      }
    end)
  end

  defp stage_module(stage_type) when is_activity_stage(stage_type), do: ActivityStage
  defp stage_module(stage_type) when is_race_stage(stage_type), do: RaceStage
  defp stage_module(stage_type) when is_segment_stage(stage_type), do: SegmentStage
end
