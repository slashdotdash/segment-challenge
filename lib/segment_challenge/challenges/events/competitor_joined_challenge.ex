defmodule SegmentChallenge.Events.CompetitorJoinedChallenge do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :athlete_uuid,
    :gender
  ]
end
