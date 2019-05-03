defmodule SegmentChallenge.Stages.Stage.ActivityStage do
  use SegmentChallenge.Stages.Stage.Aliases

  import SegmentChallenge.Stages.Stage.Guards

  alias SegmentChallenge.Stages.Stage
  alias SegmentChallenge.Stages.Stage.StageEffort

  @behaviour Stage

  @doc """
  Create an activity stage in a challenge.
  """
  @impl Stage
  def create(%CreateActivityStage{} = command) do
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
      accumulate_activities: accumulate_activities?,
      has_goal: has_goal?,
      goal: goal,
      goal_units: goal_units,
      visible: visible?,
      created_by_athlete_uuid: created_by_athlete_uuid,
      slugger: slugger
    } = command

    {:ok, url_slug} = slugger.(challenge_uuid, stage_uuid, name)

    created = %StageCreated{
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
      accumulate_activities?: accumulate_activities?,
      created_by_athlete_uuid: created_by_athlete_uuid,
      visible?: visible?,
      url_slug: url_slug
    }

    if has_goal? do
      [
        created,
        %StageGoalConfigured{
          stage_uuid: stage_uuid,
          goal: goal,
          goal_measure: rank_by(stage_type),
          goal_units: goal_units
        }
      ]
    else
      created
    end
  end

  @impl Stage
  def rank_by(stage_type)
  def rank_by("distance"), do: "distance_in_metres"
  def rank_by("duration"), do: "moving_time_in_seconds"
  def rank_by("elevation"), do: "elevation_gain_in_metres"

  @impl Stage
  def rank_order(stage_type) when is_activity_stage(stage_type), do: "desc"

  @impl Stage
  def is_valid_stage_effort?(%Stage{stage_type: stage_type}, %StageEffort{})
      when is_activity_stage(stage_type),
      do: true
end
