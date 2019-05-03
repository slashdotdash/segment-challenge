defmodule SegmentChallenge.Events.StageLeaderboardCleared do
  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid
  ]
end
