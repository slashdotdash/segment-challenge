defmodule SegmentChallenge.Projections.StageProjection do
  use Ecto.Schema

  alias SegmentChallenge.Challenges.Formatters.DistanceFormatter
  alias SegmentChallenge.Projections.StageProjection

  @primary_key {:stage_uuid, :string, []}

  defmodule StageType do
    use Exnumerator,
      values: [
        # Activity stage types
        "distance",
        "duration",
        "elevation",
        # Segment stage types
        "flat",
        "mountain",
        "rolling",
        # Virtual race stage types
        "race"
      ]
  end

  defmodule Units do
    use Exnumerator,
      values: [
        "metres",
        "kilometres",
        "feet",
        "miles",
        "seconds",
        "minutes",
        "hours",
        "days"
      ]
  end

  schema "stages" do
    field(:stage_number, :integer)
    field(:name, :string)
    field(:description_markdown, :string)
    field(:description_html, :string)
    field(:stage_type, StageType)
    field(:strava_segment_id, :integer)
    field(:start_date, :naive_datetime)
    field(:start_date_local, :naive_datetime)
    field(:end_date, :naive_datetime)
    field(:end_date_local, :naive_datetime)
    field(:start_description_html, :string)
    field(:end_description_html, :string)
    field(:distance_in_metres, :float)
    field(:average_grade, :float)
    field(:maximum_grade, :float)
    field(:start_latitude, :float)
    field(:start_longitude, :float)
    field(:end_latitude, :float)
    field(:end_longitude, :float)
    field(:map_polyline, :string)
    field(:attempt_count, :integer, default: 0)
    field(:competitor_count, :integer, default: 0)
    field(:allow_private_activities, :boolean, default: false)
    field(:included_activity_types, {:array, :string}, default: [])
    field(:accumulate_activities, :boolean, default: false)
    field(:has_goal, :boolean, default: false)
    field(:goal, :float)
    field(:goal_units, Units)
    field(:refreshed_at, :naive_datetime)
    field(:challenge_uuid, :string)
    field(:url_slug, :string)
    field(:created_by_athlete_uuid, :string)
    field(:status, :string, default: "pending")
    field(:approved, :boolean, default: false)
    field(:results_markdown, :string)
    field(:results_html, :string)
    field(:visible, :boolean, default: false)

    timestamps()
  end

  def goal_distance_in_metres(%StageProjection{} = stage) do
    %StageProjection{goal: goal, goal_units: goal_units} = stage

    DistanceFormatter.goal_in_metres(goal, goal_units)
  end
end
