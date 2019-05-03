defmodule SegmentChallenge.Events.StageRevealed do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
  ]
end
