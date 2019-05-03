defmodule SegmentChallenge.Events.ChallengeLeaderboardsApproved do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :approved_by_athlete_uuid,
    :approved_by_club_uuid,
    :approval_message,
  ]
end
