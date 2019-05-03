defmodule SegmentChallenge.Commands.RemoveStageEffortFromStageLeaderboard do
  defstruct [
    :stage_leaderboard_uuid,
    :strava_activity_id,
    :strava_segment_effort_id,
    :athlete_uuid,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :reason,
    :removed_at
  ]

  use Vex.Struct

  validates(:stage_leaderboard_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  validates(:strava_activity_id, by: [function: &is_integer/1, allow_nil: false])
  validates(:strava_segment_effort_id, by: [function: &is_integer/1, allow_nil: true])
  validates(:elapsed_time_in_seconds, presence: true, by: &is_integer/1)
  validates(:moving_time_in_seconds, presence: true, by: &is_integer/1)
  validates(:distance_in_metres, presence: true, by: &is_number/1)
  validates(:elevation_gain_in_metres, by: [function: &is_number/1, allow_nil: true])
  validates(:reason, string: true)
  validates(:removed_at, presence: true, naivedatetime: true)
end
