defmodule SegmentChallenge.Commands.ReconfigureChallengeLeaderboardPoints do
  defstruct [
    :challenge_leaderboard_uuid,
    :points,
  ]

  use Vex.Struct

  validates :challenge_leaderboard_uuid, uuid: true
  validates :points, presence: true
end
