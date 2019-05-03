defmodule SegmentChallenge.Projections.ChallengeLeaderboardProjection do
  use Ecto.Schema

  @primary_key {:challenge_leaderboard_uuid, :string, []}

  defmodule ChallengeType do
    use Exnumerator, values: ["segment", "distance", "duration", "elevation", "race"]
  end

  defmodule RankBy do
    use Exnumerator,
      values: [
        "points",
        "goals",
        "elapsed_time_in_seconds",
        "moving_time_in_seconds",
        "distance_in_metres",
        "elevation_gain_in_metres"
      ]
  end

  defmodule RankOrder do
    use Exnumerator, values: ["asc", "desc"]
  end

  defmodule Units do
    use Exnumerator,
      values: ["metres", "kilometres", "feet", "miles", "seconds", "minutes", "hours", "days"]
  end

  defmodule Recurrence do
    use Exnumerator, values: ["none", "day", "week", "month"]
  end

  schema "challenge_leaderboards" do
    field(:challenge_uuid, :string)
    field(:challenge_type, ChallengeType)
    field(:name, :string)
    field(:description, :string)
    field(:gender, :string)
    field(:rank_by, RankBy)
    field(:rank_order, RankOrder)
    field(:accumulate_activities, :boolean, default: false)
    field(:has_goal, :boolean, default: false)
    field(:goal, :float)
    field(:goal_units, Units)
    field(:goal_recurrence, Recurrence)

    timestamps()
  end
end
