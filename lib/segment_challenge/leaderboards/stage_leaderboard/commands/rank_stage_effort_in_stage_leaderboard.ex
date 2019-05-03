defmodule SegmentChallenge.Commands.RankStageEffortInStageLeaderboard do
  defstruct [
    :stage_leaderboard_uuid,
    :athlete_uuid,
    :athlete_gender,
    :strava_activity_id,
    :strava_segment_effort_id,
    :activity_type,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :start_date,
    :start_date_local,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :average_cadence,
    :average_watts,
    :device_watts?,
    :average_heartrate,
    :max_heartrate,
    :private?
  ]

  use Vex.Struct

  validates(:stage_leaderboard_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  validates(:athlete_gender, presence: true, gender: true)
  validates(:strava_activity_id, by: [function: &is_integer/1, allow_nil: false])
  validates(:strava_segment_effort_id, by: [function: &is_integer/1, allow_nil: true])
  validates(:activity_type, activity_type: true)
  validates(:elapsed_time_in_seconds, presence: true, by: &is_integer/1)
  validates(:moving_time_in_seconds, presence: true, by: &is_integer/1)
  validates(:start_date, presence: true, naivedatetime: true)
  validates(:start_date_local, presence: true, naivedatetime: true)
  validates(:distance_in_metres, presence: true, by: &is_number/1)
  validates(:elevation_gain_in_metres, by: [function: &is_number/1, allow_nil: true])
  validates(:average_cadence, by: [function: &is_number/1, allow_nil: true])
  validates(:average_watts, by: [function: &is_number/1, allow_nil: true])
  validates(:device_watts?, by: [function: &is_boolean/1, allow_nil: true])
  validates(:average_heartrate, by: [function: &is_number/1, allow_nil: true])
  validates(:max_heartrate, by: [function: &is_number/1, allow_nil: true])
  validates(:private?, by: [function: &is_boolean/1, allow_nil: true])
end
