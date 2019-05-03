defmodule SegmentChallenge.Events.ChallengeLeaderboardPointsReconfigured do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :points,
  ]
end
