defmodule SegmentChallenge.Projections.ChallengeLimitedCompetitorProjection do
  use Ecto.Schema

  schema "challenge_limited_competitors" do
    field(:challenge_uuid, :string)
    field(:athlete_uuid, :string)
    field(:reason, :string)

    timestamps()
  end
end
