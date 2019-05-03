defmodule SegmentChallenge.Commands.LimitCompetitorPointScoringInChallengeLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
    :athlete_uuid,
    :reason,
  ]

  use Vex.Struct

  validates :challenge_leaderboard_uuid, uuid: true
  validates :athlete_uuid, uuid: true
  validates :reason, presence: true, string: true
end
