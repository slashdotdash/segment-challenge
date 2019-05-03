defmodule SegmentChallenge.Events.StageSegmentChanged do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :strava_segment_id,
  ]
end
