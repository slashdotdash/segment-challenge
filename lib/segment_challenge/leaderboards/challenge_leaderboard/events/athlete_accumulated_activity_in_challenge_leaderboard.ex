defmodule SegmentChallenge.Events.AthleteAccumulatedActivityInChallengeLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :challenge_type,
    :stage_uuid,
    :athlete_uuid,
    :gender,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :goals,
    :goal_progress,
    :activity_count
  ]
end
