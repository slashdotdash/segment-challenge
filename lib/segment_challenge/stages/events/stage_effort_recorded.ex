defmodule SegmentChallenge.Events.StageEffortRecorded do
  alias SegmentChallenge.Events.StageEffortRecorded

  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
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
    :trainer?,
    :commute?,
    :manual?,
    :private?,
    :flagged?,
    :average_cadence,
    :average_watts,
    :device_watts?,
    :average_heartrate,
    :max_heartrate,
    :attempt_count,
    :competitor_count,
    stage_type: "segment"
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    alias SegmentChallenge.NaiveDateTimeParser

    def decode(%StageEffortRecorded{} = event) do
      %StageEffortRecorded{start_date: start_date, start_date_local: start_date_local} = event

      %StageEffortRecorded{
        event
        | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
          start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local)
      }
    end
  end
end
