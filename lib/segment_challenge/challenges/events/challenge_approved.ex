defmodule SegmentChallenge.Events.ChallengeApproved do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :approved_by_athlete_uuid,
  ]
end
