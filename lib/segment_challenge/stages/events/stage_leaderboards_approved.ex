defmodule SegmentChallenge.Events.StageLeaderboardsApproved do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :approved_by_athlete_uuid,
    :approved_by_club_uuid,
    :approval_message,
  ]
end
