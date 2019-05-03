defmodule SegmentChallenge.Events.ChallengeStarted do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :start_date,
    :start_date_local,
  ]
end
