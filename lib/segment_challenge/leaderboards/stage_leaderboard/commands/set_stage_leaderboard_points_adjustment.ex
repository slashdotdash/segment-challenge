defmodule SegmentChallenge.Commands.SetStageLeaderboardPointsAdjustment do
  defstruct [
    :stage_leaderboard_uuid,
    :points_adjustment,
  ]

  use Vex.Struct

  validates :stage_leaderboard_uuid, uuid: true
  validates :points_adjustment, pointsadjustment: true
end
