defmodule SegmentChallenge.Events.StageLeaderboardPointsAdjusted do
  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :points_adjustment,
  ]
end
