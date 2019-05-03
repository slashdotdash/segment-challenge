defmodule SegmentChallenge.Events.AthleteAccumulatedPointsInChallengeLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :athlete_uuid,
    :gender,
    :points,
    challenge_type: "segment"
  ]
end
