defmodule SegmentChallenge.Events.ChallengeLeaderboardFinalised do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :entries,
    challenge_type: "segment"
  ]
end
