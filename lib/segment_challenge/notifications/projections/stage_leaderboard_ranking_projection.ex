defmodule SegmentChallenge.Projections.StageLeaderboardRankingProjection do
  use Ecto.Schema

  schema "stage_leaderboard_rankings" do
    field(:stage_leaderboard_uuid, :string)
    field(:challenge_uuid, :string)
    field(:stage_uuid, :string)
    field(:rank, :integer)
    field(:athlete_uuid, :string)
    field(:athlete_firstname, :string)
    field(:athlete_lastname, :string)
    field(:athlete_profile, :string)
    field(:elapsed_time_in_seconds, :integer)

    timestamps()
  end
end
