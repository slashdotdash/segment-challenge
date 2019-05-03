defmodule SegmentChallenge.Events.StageRemovedFromChallenge do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
  ]
end
