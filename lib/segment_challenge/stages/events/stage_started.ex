defmodule SegmentChallenge.Events.StageStarted do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
    :start_date,
    :start_date_local,
  ]
end
