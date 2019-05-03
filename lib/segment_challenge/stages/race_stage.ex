defmodule SegmentChallenge.Stages.Stage.RaceStage do
  use SegmentChallenge.Stages.Stage.Aliases

  import SegmentChallenge.Stages.Stage.Guards

  alias SegmentChallenge.Stages.Stage
  alias SegmentChallenge.Stages.Stage.StageEffort

  @behaviour Stage

  @doc """
  Create a race stage in a challenge.
  """
  @impl Stage
  def create(%CreateRaceStage{} = command) do
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
      created_by_athlete_uuid: created_by_athlete_uuid,
      slugger: slugger
    } = command

    {:ok, url_slug} = slugger.(challenge_uuid, stage_uuid, name)

    [
      %StageCreated{
        stage_uuid: stage_uuid,
        challenge_uuid: challenge_uuid,
        stage_type: stage_type,
        stage_number: stage_number,
        name: name,
        description: description,
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local,
        allow_private_activities?: allow_private_activities?,
        included_activity_types: included_activity_types,
        accumulate_activities?: false,
        created_by_athlete_uuid: created_by_athlete_uuid,
        visible?: visible?,
        url_slug: url_slug
      },
      %StageGoalConfigured{
        stage_uuid: stage_uuid,
        goal: goal,
        goal_measure: "distance_in_metres",
        goal_units: goal_units
      }
    ]
  end

  @impl Stage
  def rank_by(stage_type) when is_race_stage(stage_type), do: "elapsed_time_in_seconds"

  @impl Stage
  def rank_order(stage_type) when is_race_stage(stage_type), do: "asc"

  @impl Stage
  def is_valid_stage_effort?(
        %Stage{stage_type: stage_type} = stage,
        %StageEffort{} = stage_effort
      )
      when is_race_stage(stage_type) do
    %Stage{goal_in_units: goal_in_units} = stage

    StageEffort.achieved_goal?(stage_effort, :distance_in_metres, goal_in_units)
  end
end
