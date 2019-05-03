defmodule SegmentChallenge.Stages.Stage.SegmentStage do
  use SegmentChallenge.Stages.Stage.Aliases

  import SegmentChallenge.Stages.Stage.Guards

  alias SegmentChallenge.Stages.Stage
  alias SegmentChallenge.Stages.Stage.StageEffort
  alias SegmentChallenge.Stages.Stage.Commands.CreateSegmentStage.Segment

  @behaviour Stage

  @doc """
  Create a single stage in a challenge.
  """
  @impl Stage
  def create(%CreateSegmentStage{} = command) do
    %CreateSegmentStage{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      name: name,
      description: description,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      allow_private_activities: allow_private_activities?,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      start_description: start_description,
      end_description: end_description,
      visible: visible?,
      created_by_athlete_uuid: created_by_athlete_uuid,
      slugger: slugger,
      strava_segment_factory: strava_segment_factory
    } = command

    {:ok, %Segment{} = segment} = strava_segment_factory.(command)
    {:ok, url_slug} = slugger.(challenge_uuid, stage_uuid, name)

    %Segment{
      strava_segment_id: strava_segment_id,
      activity_type: activity_type,
      distance_in_metres: distance_in_metres,
      average_grade: average_grade,
      maximum_grade: maximum_grade,
      elevation_high: elevation_high,
      elevation_low: elevation_low,
      start_latlng: start_latlng,
      end_latlng: end_latlng,
      climb_category: climb_category,
      city: city,
      state: state,
      country: country,
      total_elevation_gain: total_elevation_gain,
      map_polyline: map_polyline
    } = segment

    [
      %StageCreated{
        stage_uuid: stage_uuid,
        challenge_uuid: challenge_uuid,
        stage_number: stage_number,
        stage_type: stage_type,
        name: name,
        description: description,
        points_adjustment: points_adjustment,
        allow_private_activities?: allow_private_activities?,
        included_activity_types: [activity_type],
        accumulate_activities?: false,
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local,
        created_by_athlete_uuid: created_by_athlete_uuid,
        visible?: visible?,
        url_slug: url_slug
      },
      %StageSegmentConfigured{
        stage_uuid: stage_uuid,
        strava_segment_id: strava_segment_id,
        start_description: start_description,
        end_description: end_description,
        distance_in_metres: distance_in_metres,
        average_grade: average_grade,
        maximum_grade: maximum_grade,
        elevation_high: elevation_high,
        elevation_low: elevation_low,
        start_latlng: start_latlng,
        end_latlng: end_latlng,
        climb_category: climb_category,
        city: city,
        state: state,
        country: country,
        total_elevation_gain: total_elevation_gain,
        map_polyline: map_polyline
      }
    ]
  end

  @impl Stage
  def rank_by(stage_type) when is_segment_stage(stage_type), do: "elapsed_time_in_seconds"

  @impl Stage
  def rank_order(stage_type) when is_segment_stage(stage_type), do: "asc"

  @impl Stage
  def is_valid_stage_effort?(%Stage{stage_type: stage_type}, %StageEffort{})
      when is_segment_stage(stage_type),
      do: true
end
