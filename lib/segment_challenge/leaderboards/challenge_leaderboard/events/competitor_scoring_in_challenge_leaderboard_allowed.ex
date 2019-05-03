defmodule SegmentChallenge.Events.CompetitorScoringInChallengeLeaderboardAllowed do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :athlete_uuid
  ]
end
