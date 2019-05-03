defmodule SegmentChallenge.Commands.RemoveChallengeLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
  ]

  use Vex.Struct

  validates :challenge_leaderboard_uuid, uuid: true
end
