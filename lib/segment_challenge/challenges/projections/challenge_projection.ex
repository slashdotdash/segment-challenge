defmodule SegmentChallenge.Projections.ChallengeProjection do
  use Ecto.Schema

  alias SegmentChallenge.Projections.ChallengeProjection

  defmodule ChallengeType do
    use Exnumerator,
      values: [
        "segment",
        "distance",
        "duration",
        "elevation",
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

  defmodule Recurrence do
    use Exnumerator,
      values: [
        "none",
        "day",
        "week",
        "month"
      ]
  end

  @primary_key {:challenge_uuid, :string, []}

  schema "challenges" do
    field(:challenge_type, ChallengeType, default: "segment")
    field(:name, :string)
    field(:description_markdown, :string)
    field(:description_html, :string)
    field(:summary_html, :string)
    field(:start_date, :naive_datetime)
    field(:start_date_local, :naive_datetime)
    field(:end_date, :naive_datetime)
    field(:end_date_local, :naive_datetime)
    field(:stage_count, :integer, default: 0)
    field(:competitor_count, :integer, default: 0)
    field(:hosted_by_club_uuid, :string)
    field(:hosted_by_club_name, :string)
    field(:created_by_athlete_uuid, :string)
    field(:created_by_athlete_name, :string)
    field(:url_slug, :string)
    field(:included_activity_types, {:array, :string}, default: [])
    field(:status, :string, default: "pending")
    field(:stages_configured, :boolean, default: false)
    field(:approved, :boolean, default: false)
    field(:results_markdown, :string)
    field(:results_html, :string)
    field(:restricted_to_club_members, :boolean, default: true)
    field(:allow_private_activities, :boolean, default: false)
    field(:accumulate_activities, :boolean, default: false)
    field(:private, :boolean, default: false)

    # Challenge goal
    field(:has_goal, :boolean, default: false)
    field(:goal, :float)
    field(:goal_units, Units)
    field(:goal_recurrence, Recurrence)

    timestamps()
  end

  def hide_challenge_stages?(%ChallengeProjection{stage_count: 1, challenge_type: challenge_type})
      when challenge_type in ["distance", "duration", "elevation", "race"],
      do: true

  def hide_challenge_stages?(%ChallengeProjection{}), do: false
end
