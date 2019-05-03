defmodule SegmentChallenge.Events.ChallengeHosted do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :hosted_by_athlete_uuid,
  ]
end
