defmodule SegmentChallenge.Stages.Stage.Commands.ImportStageEfforts do
  defstruct [:stage_uuid, stage_efforts: []]

  defmodule StageEffort do
    defstruct [
      :athlete_uuid,
      :strava_activity_id,
      :strava_segment_effort_id,
      :activity_type,
      :activity_name,
      :elapsed_time_in_seconds,
      :moving_time_in_seconds,
      :distance_in_metres,
      :elevation_gain_in_metres,
      :start_date,
      :start_date_local,
      :trainer?,
      :commute?,
      :manual?,
      :private?,
      :flagged?,
      :average_cadence,
      :average_watts,
      :device_watts?,
      :average_heartrate,
      :max_heartrate
    ]

    use Vex.Struct

    validates(:athlete_uuid, uuid: true)
    validates(:strava_activity_id, presence: true, by: &is_integer/1)
    validates(:strava_segment_effort_id, by: [function: &is_integer/1, allow_nil: true])
    validates(:activity_type, activity_type: true)
    validates(:elapsed_time_in_seconds, presence: true, by: &is_integer/1)
    validates(:moving_time_in_seconds, presence: true, by: &is_integer/1)
    validates(:distance_in_metres, by: &is_number/1)
    validates(:elevation_gain_in_metres, by: [function: &is_number/1, allow_nil: true])
    validates(:start_date, presence: true, naivedatetime: true)
    validates(:start_date_local, presence: true, naivedatetime: true)
    validates(:trainer?, by: [function: &is_boolean/1, allow_nil: true])
    validates(:commute?, by: [function: &is_boolean/1, allow_nil: true])
    validates(:manual?, by: [function: &is_boolean/1, allow_nil: true])
    validates(:private?, by: [function: &is_boolean/1, allow_nil: true])
    validates(:flagged?, by: [function: &is_boolean/1, allow_nil: true])
    validates(:average_cadence, by: [function: &is_number/1, allow_nil: true])
    validates(:average_watts, by: [function: &is_number/1, allow_nil: true])
    validates(:device_watts?, by: [function: &is_boolean/1, allow_nil: true])
    validates(:average_heartrate, by: [function: &is_number/1, allow_nil: true])
    validates(:max_heartrate, by: [function: &is_number/1, allow_nil: true])
  end

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:stage_efforts, stage_efforts: true)
end
