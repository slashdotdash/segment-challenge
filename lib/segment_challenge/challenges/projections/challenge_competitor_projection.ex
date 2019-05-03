defmodule SegmentChallenge.Projections.ChallengeCompetitorProjection do
  use Ecto.Schema

  @primary_key false

  schema "challenge_competitors" do
    field(:athlete_uuid, :string, primary_key: true)
    field(:challenge_uuid, :string, primary_key: true)
    field(:joined_at, :naive_datetime)

    timestamps()
  end
end
