defmodule SegmentChallenge.Commands.RemoveCompetitorFromChallengeLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :athlete_uuid,
  ]

  use Vex.Struct

  validates :challenge_leaderboard_uuid, uuid: true
  validates :challenge_uuid, uuid: true
  validates :athlete_uuid, uuid: true
end
