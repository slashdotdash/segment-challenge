defmodule SegmentChallenge.Events.ChallengeStageStartRequested do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
  ]
end
