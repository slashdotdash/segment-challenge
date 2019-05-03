defmodule SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection do
  use Ecto.Schema

  @primary_key {:stage_leaderboard_uuid, :string, []}

  defmodule StageType do
    use Exnumerator,
      values: [
        "activity",
        "segment",

        # Segment stage types
        "mountain",
        "rolling",
        "flat",

        # Activity stage types
        "distance",
        "duration",
        "elevation",

        # Race stage types
        "race"
      ]
  end

  defmodule Measure do
    use Exnumerator,
      values: [
        "distance_in_metres",
        "elapsed_time_in_seconds",
        "moving_time_in_seconds",
        "elevation_gain_in_metres"
      ]
  end

  defmodule RankOrder do
    use Exnumerator,
      values: [
        "asc",
        "desc"
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

  schema "stage_leaderboards" do
    field(:challenge_uuid, :string)
    field(:stage_uuid, :string)
    field(:stage_type, StageType)
    field(:name, :string)
    field(:gender, :string)
    field(:rank_by, Measure)
    field(:rank_order, RankOrder)
    field(:accumulate_activities, :boolean, default: false)
    field(:has_goal, :boolean, default: false)
    field(:goal, :float)
    field(:goal_measure, Measure)
    field(:goal_units, Units)

    timestamps()
  end
end
