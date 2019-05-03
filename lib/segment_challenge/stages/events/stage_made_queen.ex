defmodule SegmentChallenge.Events.StageMadeQueen do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
  ]
end
