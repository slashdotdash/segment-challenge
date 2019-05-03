defmodule SegmentChallenge.Stages.Stage.Commands.RecordManualStageEffort do
  defstruct [
    :stage_uuid,
    :athlete_uuid,
    :strava_segment_effort_id,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :start_date,
    :start_date_local,
    :distance_in_metres,
    :average_cadence,
    :average_watts,
    :device_watts?,
    :average_heartrate,
    :max_heartrate
  ]

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  validates(:strava_segment_effort_id, presence: true, by: &is_integer/1)
  validates(:elapsed_time_in_seconds, presence: true, by: &is_integer/1)
  validates(:moving_time_in_seconds, presence: true, by: &is_integer/1)
  validates(:start_date, presence: true, naivedatetime: true)
  validates(:start_date_local, presence: true, naivedatetime: true)
  validates(:distance_in_metres, presence: true, by: &is_number/1)
  validates(:average_cadence, by: [function: &is_number/1, allow_nil: true])
  validates(:average_watts, by: [function: &is_number/1, allow_nil: true])
  validates(:device_watts?, by: [function: &is_boolean/1, allow_nil: true])
  validates(:average_heartrate, by: [function: &is_number/1, allow_nil: true])
  validates(:max_heartrate, by: [function: &is_number/1, allow_nil: true])
end
