defmodule SegmentChallenge.Projections.StageEffortProjection do
  use Ecto.Schema

  schema "stage_efforts" do
    field(:stage_uuid, :string, null: false)
    field(:athlete_uuid, :string, null: false)
    field(:athlete_gender, :string)
    field(:strava_activity_id, :integer, null: false)
    field(:strava_segment_effort_id, :integer)
    field(:activity_type, :string)
    field(:elapsed_time_in_seconds, :integer)
    field(:moving_time_in_seconds, :integer)
    field(:distance_in_metres, :float)
    field(:elevation_gain_in_metres, :float)
    field(:start_date, :naive_datetime)
    field(:start_date_local, :naive_datetime)
    field(:trainer, :boolean)
    field(:commute, :boolean)
    field(:manual, :boolean)
    field(:private, :boolean)
    field(:flagged, :boolean, default: false)
    field(:flagged_reason, :string)
    field(:speed_in_mph, :float)
    field(:speed_in_kph, :float)
    field(:average_cadence, :float)
    field(:average_watts, :float)
    field(:device_watts, :boolean, default: false)
    field(:average_heartrate, :float)
    field(:max_heartrate, :float)

    timestamps()
  end
end
