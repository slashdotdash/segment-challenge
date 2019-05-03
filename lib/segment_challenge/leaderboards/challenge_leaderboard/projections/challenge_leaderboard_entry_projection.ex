defmodule SegmentChallenge.Projections.ChallengeLeaderboardEntryProjection do
  use Ecto.Schema

  schema "challenge_leaderboard_entries" do
    field(:challenge_leaderboard_uuid, :string)
    field(:challenge_uuid, :string)
    field(:rank, :integer)
    field(:points, :integer)
    field(:elapsed_time_in_seconds, :integer)
    field(:moving_time_in_seconds, :integer)
    field(:distance_in_metres, :float)
    field(:elevation_gain_in_metres, :float)
    field(:goals, :integer)
    field(:goal_progress, :map)
    field(:activity_count, :integer)
    field(:athlete_uuid, :string)
    field(:athlete_firstname, :string)
    field(:athlete_lastname, :string)
    field(:athlete_gender, :string)
    field(:athlete_profile, :string)

    timestamps()
  end
end
