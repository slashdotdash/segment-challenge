defmodule SegmentChallenge.Events.ChallengeEnded do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :end_date,
    :end_date_local,
    :hosted_by_club_uuid,
  ]
end
