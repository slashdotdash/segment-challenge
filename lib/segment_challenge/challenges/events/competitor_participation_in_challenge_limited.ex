defmodule SegmentChallenge.Events.CompetitorParticipationInChallengeLimited do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :athlete_uuid,
    :reason,
  ]
end
