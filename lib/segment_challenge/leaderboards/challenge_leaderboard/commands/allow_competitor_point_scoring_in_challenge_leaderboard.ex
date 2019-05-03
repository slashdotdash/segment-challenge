defmodule SegmentChallenge.Commands.AllowCompetitorPointScoringInChallengeLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
    :athlete_uuid
  ]

  use Vex.Struct

  validates(:challenge_leaderboard_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
end
