defmodule SegmentChallenge.Events.ChallengeLeaderboardRemoved do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
  ]
end
