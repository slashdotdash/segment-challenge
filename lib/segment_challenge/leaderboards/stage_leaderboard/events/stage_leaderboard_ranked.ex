defmodule SegmentChallenge.Events.StageLeaderboardRanked do
  alias SegmentChallenge.Events.StageLeaderboardRanked
  alias SegmentChallenge.Events.StageLeaderboardRanked.Ranking
  alias SegmentChallenge.Events.StageLeaderboardRanked.StageEffort

  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :stage_uuid,
    :challenge_uuid,
    :stage_efforts,
    new_positions: [],
    positions_gained: [],
    positions_lost: [],
    has_goal?: false
  ]

  defmodule Ranking do
    @derive Jason.Encoder
    defstruct [
      :athlete_uuid,
      :rank,
      :positions_changed
    ]
  end

  defmodule StageEffort do
    import SegmentChallenge.Serialization.Helpers
    alias SegmentChallenge.NaiveDateTimeParser

    @derive Jason.Encoder
    defstruct [
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

    def decode(%StageEffort{} = stage_effort) do
      %StageEffort{
        start_date: start_date,
        start_date_local: start_date_local,
        goal_progress: goal_progress
      } = stage_effort

      %StageEffort{
        stage_effort
        | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
          start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local),
          goal_progress: to_decimal(goal_progress)
      }
    end
  end

  defimpl Commanded.Serialization.JsonDecoder do
    import SegmentChallenge.Enumerable

    def decode(%StageLeaderboardRanked{} = event) do
      %StageLeaderboardRanked{
        stage_efforts: stage_efforts,
        new_positions: new_positions,
        positions_gained: positions_gained,
        positions_lost: positions_lost
      } = event

      stage_efforts =
        case stage_efforts do
          nil -> nil
          stage_efforts -> map_to_struct(stage_efforts, StageEffort, &StageEffort.decode/1)
        end

      %StageLeaderboardRanked{
        event
        | stage_efforts: stage_efforts,
          new_positions: map_to_struct(new_positions, Ranking),
          positions_gained: map_to_struct(positions_gained, Ranking),
          positions_lost: map_to_struct(positions_lost, Ranking)
      }
    end
  end
end
