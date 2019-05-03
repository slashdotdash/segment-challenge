defmodule SegmentChallenge.Events.StageDurationAdjusted do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
  ]
end
