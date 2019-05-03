defmodule SegmentChallenge.Events.StageEnded do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
    :end_date,
    :end_date_local,
  ]
end
