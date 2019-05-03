defmodule SegmentChallenge.Events.PendingAdjustmentInStageLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
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
    private?: false
  ]
end
