defmodule SegmentChallenge.Events.StageIncludedInChallenge do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
    :name,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
  ]
end
