defmodule SegmentChallenge.Leaderboards.StageLeaderboard.Results do
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

  defmodule ChallengeStageProjection do
    use Ecto.Schema

    schema "stage_result_challenge_stages" do
      field(:challenge_uuid, :string)
      field(:stage_uuid, :string)
      field(:stage_number, :integer)

      timestamps()
    end
  end

  defmodule ChallengeLeaderboardProjection do
    use Ecto.Schema

    schema "stage_result_challenge_leaderboards" do
      field(:challenge_uuid, :string)
      field(:challenge_leaderboard_uuid, :string)
      field(:name, :string)
      field(:description, :string)
      field(:gender, :string)
      field(:rank_by, RankBy)
      field(:rank_order, RankOrder)
      field(:has_goal, :boolean, default: false)
      field(:goal, :float)
      field(:goal_units, Units)
      field(:goal_recurrence, Recurrence)

      timestamps()
    end
  end

  defmodule StageResultProjection do
    use Ecto.Schema

    schema "stage_results" do
      field(:challenge_uuid, :string)
      field(:challenge_leaderboard_uuid, :string)
      field(:stage_uuid, :string)
      field(:stage_number, :integer)
      field(:current_stage_number, :integer)
      field(:name, :string)
      field(:description, :string)
      field(:gender, :string)
      field(:rank_by, RankBy)
      field(:rank_order, RankOrder)
      field(:has_goal, :boolean, default: false)
      field(:goal, :float)
      field(:goal_units, Units)
      field(:goal_recurrence, Recurrence)

      timestamps()
    end
  end

  defmodule StageResultEntryProjection do
    use Ecto.Schema

    schema "stage_result_entries" do
      field(:challenge_uuid, :string)
      field(:challenge_leaderboard_uuid, :string)
      field(:stage_uuid, :string)
      field(:stage_number, :integer)
      field(:rank, :integer)
      field(:rank_change, :integer)
      field(:points, :integer, default: 0)
      field(:points_gained, :integer, default: 0)
      field(:elapsed_time_in_seconds, :integer, default: 0)
      field(:elapsed_time_in_seconds_gained, :integer, default: 0)
      field(:moving_time_in_seconds, :integer, default: 0)
      field(:moving_time_in_seconds_gained, :integer, default: 0)
      field(:distance_in_metres, :float, default: 0.0)
      field(:distance_in_metres_gained, :float, default: 0.0)
      field(:elevation_gain_in_metres, :float, default: 0.0)
      field(:elevation_gain_in_metres_gained, :float, default: 0.0)
      field(:goals, :integer, default: 0)
      field(:goals_gained, :integer, default: 0)
      field(:activity_count, :integer, default: 0)
      field(:athlete_uuid, :string)
      field(:athlete_firstname, :string)
      field(:athlete_lastname, :string)
      field(:athlete_gender, :string)
      field(:athlete_profile, :string)

      timestamps()
    end
  end
end
