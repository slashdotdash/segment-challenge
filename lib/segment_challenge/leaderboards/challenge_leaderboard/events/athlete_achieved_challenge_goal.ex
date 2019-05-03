defmodule SegmentChallenge.Events.AthleteAchievedChallengeGoal do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :athlete_uuid
  ]
end
