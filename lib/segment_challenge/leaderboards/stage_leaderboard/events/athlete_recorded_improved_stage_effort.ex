defmodule SegmentChallenge.Events.AthleteRecordedImprovedStageEffort do
  alias SegmentChallenge.Events.AthleteRecordedImprovedStageEffort

  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :rank,
    :athlete_uuid,
    :athlete_gender,
    :strava_activity_id,
    :strava_segment_effort_id,
    :activity_type,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :start_date,
    :start_date_local,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :average_cadence,
    :average_watts,
    :device_watts?,
    :average_heartrate,
    :max_heartrate,
    :goal_progress,
    :stage_effort_count,
    private?: false
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    import SegmentChallenge.Serialization.Helpers
    alias SegmentChallenge.NaiveDateTimeParser

    def decode(%AthleteRecordedImprovedStageEffort{} = event) do
      %AthleteRecordedImprovedStageEffort{
        start_date: start_date,
        start_date_local: start_date_local,
        goal_progress: goal_progress
      } = event

      %AthleteRecordedImprovedStageEffort{
        event
        | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
          start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local),
          goal_progress: to_decimal(goal_progress)
      }
    end
  end
end
