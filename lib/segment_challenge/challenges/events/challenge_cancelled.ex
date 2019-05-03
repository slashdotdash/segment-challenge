defmodule SegmentChallenge.Events.ChallengeCancelled do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :cancelled_by_athlete_uuid,
    :hosted_by_club_uuid,
  ]
end
