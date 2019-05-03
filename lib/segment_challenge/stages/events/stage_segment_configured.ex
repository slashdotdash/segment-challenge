defmodule SegmentChallenge.Events.StageSegmentConfigured do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :strava_segment_id,
    :start_description,
    :end_description,
    :distance_in_metres,
    :average_grade,
    :maximum_grade,
    :elevation_high,
    :elevation_low,
    :start_latlng,
    :end_latlng,
    :climb_category,
    :city,
    :state,
    :country,
    :total_elevation_gain,
    :map_polyline
  ]
end
