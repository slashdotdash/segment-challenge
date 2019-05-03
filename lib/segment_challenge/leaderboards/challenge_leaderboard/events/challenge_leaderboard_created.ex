defmodule SegmentChallenge.Events.ChallengeLeaderboardCreated do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :name,
    :description,
    :gender,
    :points,
    challenge_type: "segment",
    rank_by: "points",
    rank_order: "desc",
    has_goal?: false
  ]
end
