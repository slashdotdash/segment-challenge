defmodule SegmentChallenge.Events.StagesConfiguredInChallengeLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :stage_uuids
  ]
end
