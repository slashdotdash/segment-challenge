defmodule SegmentChallenge.Events.StageMadePreview do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
  ]
end
