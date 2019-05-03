defmodule SegmentChallenge.Events.StageEffortRemoved do
  alias SegmentChallenge.Events.StageEffortRemoved

  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :strava_activity_id,
    :strava_segment_effort_id,
    :athlete_uuid,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :start_date,
    :start_date_local,
    :attempt_count,
    :competitor_count
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    alias SegmentChallenge.NaiveDateTimeParser

    def decode(%StageEffortRemoved{start_date: nil, start_date_local: nil} = event), do: event

    def decode(%StageEffortRemoved{} = event) do
      %StageEffortRemoved{start_date: start_date, start_date_local: start_date_local} = event

      %StageEffortRemoved{
        event
        | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
          start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local)
      }
    end
  end
end
