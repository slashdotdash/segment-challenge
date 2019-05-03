defmodule SegmentChallenge.Events.AthleteRemovedFromStageLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :athlete_uuid,
    :rank,
    :removed_at,
  ]
end
