defmodule SegmentChallenge.Athletes.Projections.BadgeProjection do
  use Ecto.Schema

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

  defmodule Recurrence do
    use Exnumerator,
      values: [
        "none",
        "day",
        "week",
        "month"
      ]
  end

  schema "athlete_badges" do
    field(:athlete_uuid, :string)
    field(:challenge_uuid, :string)
    field(:challenge_name, :string)
    field(:challenge_start_date, :naive_datetime)
    field(:challenge_start_date_local, :naive_datetime)
    field(:challenge_end_date, :naive_datetime)
    field(:challenge_end_date_local, :naive_datetime)
    field(:challenge_leaderboard_uuid, :string)
    field(:hosted_by_club_uuid, :string)
    field(:hosted_by_club_name, :string)
    field(:goal, :float)
    field(:goal_units, Units)
    field(:goal_recurrence, Recurrence)
    field(:single_activity_goal, :boolean, default: false)
    field(:earned_at, :naive_datetime)

    timestamps()
  end
end
