defmodule SegmentChallenge.Commands.AdjustAthletePointsInChallengeLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
    :athlete_uuid,
    :points_adjustment
  ]

  use Vex.Struct

  validates :challenge_leaderboard_uuid, uuid: true
  validates :athlete_uuid, uuid: true
  validates :points_adjustment, by: &is_integer/1
end
