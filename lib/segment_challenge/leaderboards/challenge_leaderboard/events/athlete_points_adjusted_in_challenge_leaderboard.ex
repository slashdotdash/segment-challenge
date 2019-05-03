defmodule SegmentChallenge.Events.AthletePointsAdjustedInChallengeLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :athlete_uuid,
    :gender,
    :points_adjustment
  ]
end
