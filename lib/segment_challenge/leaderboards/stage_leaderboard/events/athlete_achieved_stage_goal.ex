defmodule SegmentChallenge.Events.AthleteAchievedStageGoal do
  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :stage_type,
    :athlete_uuid,
    :strava_activity_id,
    :strava_segment_effort_id,
    :goal,
    :goal_units,
    :single_activity_goal?
  ]
end
