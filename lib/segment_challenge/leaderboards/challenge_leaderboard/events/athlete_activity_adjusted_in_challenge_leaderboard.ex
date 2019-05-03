defmodule SegmentChallenge.Events.AthleteActivityAdjustedInChallengeLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :athlete_uuid,
    :gender,
    :elapsed_time_in_seconds_adjustment,
    :moving_time_in_seconds_adjustment,
    :distance_in_metres_adjustment,
    :elevation_gain_in_metres_adjustment,
    :goals_adjustment,
    :goal_progress_adjustment,
    :activity_count_adjustment
  ]
end
