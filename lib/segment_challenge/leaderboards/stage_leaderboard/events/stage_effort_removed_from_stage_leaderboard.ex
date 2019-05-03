defmodule SegmentChallenge.Events.StageEffortRemovedFromStageLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :rank,
    :athlete_uuid,
    :strava_activity_id,
    :strava_segment_effort_id,
    :reason,
    :replaced_by
  ]

  defmodule StageEffort do
    @derive Jason.Encoder
    defstruct [
      :strava_activity_id,
      :strava_segment_effort_id,
      :activity_type,
      :elapsed_time_in_seconds,
      :moving_time_in_seconds,
      :distance_in_metres,
      :elevation_gain_in_metres,
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
  end

  defimpl Commanded.Serialization.JsonDecoder do
    import SegmentChallenge.Serialization.Helpers

    alias SegmentChallenge.Events.StageEffortRemovedFromStageLeaderboard
    alias SegmentChallenge.Events.StageEffortRemovedFromStageLeaderboard.StageEffort
    alias SegmentChallenge.NaiveDateTimeParser

    def decode(%StageEffortRemovedFromStageLeaderboard{} = event) do
      %StageEffortRemovedFromStageLeaderboard{replaced_by: replaced_by} = event

      %StageEffortRemovedFromStageLeaderboard{event | replaced_by: replacement(replaced_by)}
    end

    defp replacement(nil), do: nil

    defp replacement(replaced_by) do
      replaced_by =
        replaced_by
        |> Map.update(:start_date, nil, &NaiveDateTimeParser.from_iso8601!/1)
        |> Map.update(:start_date_local, nil, &NaiveDateTimeParser.from_iso8601!/1)
        |> Map.update(:goal_progress, nil, &to_decimal/1)

      struct(StageEffort, replaced_by)
    end
  end
end
