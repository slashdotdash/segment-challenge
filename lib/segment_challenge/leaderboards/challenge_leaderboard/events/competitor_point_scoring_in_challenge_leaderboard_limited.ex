defmodule SegmentChallenge.Events.CompetitorScoringInChallengeLeaderboardLimited do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :athlete_uuid,
    :reason,
  ]
end
