defmodule SegmentChallenge.Events.StageEffortsCleared do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    attempt_count: 0,
    competitor_count: 0
  ]
end
