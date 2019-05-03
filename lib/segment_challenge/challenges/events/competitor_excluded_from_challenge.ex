defmodule SegmentChallenge.Events.CompetitorExcludedFromChallenge do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :athlete_uuid,
    :reason,
    :excluded_at,
  ]
end
