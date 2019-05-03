defmodule SegmentChallenge.Events.CompetitorParticipationInChallengeAllowed do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :athlete_uuid
  ]
end
