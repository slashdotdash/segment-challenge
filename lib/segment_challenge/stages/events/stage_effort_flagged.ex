defmodule SegmentChallenge.Events.StageEffortFlagged do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :strava_activity_id,
    :strava_segment_effort_id,
    :flagged_by_athlete_uuid,
    :reason,
    :athlete_uuid,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :attempt_count,
    :competitor_count
  ]
end
