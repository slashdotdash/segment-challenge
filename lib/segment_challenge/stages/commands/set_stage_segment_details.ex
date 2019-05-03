defmodule SegmentChallenge.Stages.Stage.Commands.SetStageSegmentDetails do
  defstruct [
    :stage_uuid,
    :strava_segment_id,
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

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:strava_segment_id, presence: true, by: &is_integer/1)
  validates(:distance_in_metres, presence: true, by: &is_float/1)
  validates(:average_grade, presence: true, by: &is_float/1)
  validates(:maximum_grade, presence: true, by: &is_float/1)
  validates(:elevation_high, presence: true, by: &is_float/1)
  validates(:elevation_low, presence: true, by: &is_float/1)
  validates(:start_latlng, presence: true, by: &is_list/1)
  validates(:end_latlng, presence: true, by: &is_list/1)
  validates(:climb_category, presence: true, by: &is_integer/1)
  validates(:city, string: true)
  validates(:state, string: true)
  validates(:country, string: true)
  validates(:total_elevation_gain, presence: true, by: &is_float/1)
  validates(:map_polyline, string: true)
end
