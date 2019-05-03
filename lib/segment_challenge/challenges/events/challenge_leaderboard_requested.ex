defmodule SegmentChallenge.Events.ChallengeLeaderboardRequested do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :name,
    :description,
    :gender,
    :points,
    :goal,
    :goal_units,
    challenge_type: "segment",
    rank_by: "points",
    rank_order: "desc",
    has_goal?: false
  ]
end
