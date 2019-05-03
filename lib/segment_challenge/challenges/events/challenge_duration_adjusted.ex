defmodule SegmentChallenge.Events.ChallengeDurationAdjusted do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
  ]
end
