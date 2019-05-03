defmodule SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardEntryProjection do
  use Ecto.Schema

  schema "stage_leaderboard_entries" do
    field(:stage_leaderboard_uuid, :string)
    field(:challenge_uuid, :string)
    field(:stage_uuid, :string)
    field(:rank, :integer, nil: false)
    field(:athlete_uuid, :string, nil: false)
    field(:athlete_firstname, :string)
    field(:athlete_lastname, :string)
    field(:athlete_gender, :string)
    field(:athlete_profile, :string)
    field(:strava_activity_id, :integer)
    field(:strava_segment_effort_id, :integer)
    field(:elapsed_time_in_seconds, :integer)
    field(:moving_time_in_seconds, :integer)
    field(:start_date, :naive_datetime)
    field(:start_date_local, :naive_datetime)
    field(:distance_in_metres, :float)
    field(:elevation_gain_in_metres, :float)
    field(:speed_in_mph, :float)
    field(:speed_in_kph, :float)
    field(:average_cadence, :float)
    field(:average_watts, :float)
    field(:device_watts, :boolean, default: false)
    field(:average_heartrate, :float)
    field(:max_heartrate, :float)
    field(:goal_progress, :decimal)
    field(:stage_effort_count, :integer)
    field(:athlete_point_scoring_limited, :boolean, default: false)
    field(:athlete_limit_reason, :string)

    timestamps()
  end
end
