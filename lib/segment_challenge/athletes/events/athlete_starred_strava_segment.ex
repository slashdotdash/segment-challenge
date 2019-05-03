defmodule SegmentChallenge.Events.AthleteStarredStravaSegment do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :strava_segment_id,
    :name,
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
  ]
end
