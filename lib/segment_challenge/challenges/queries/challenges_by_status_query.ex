defmodule SegmentChallenge.Challenges.Queries.Challenges.ChallengesByStatusQuery do
  import Ecto.Query
  alias SegmentChallenge.Projections.ChallengeProjection

  def new(status) when is_list(status) do
    status |> query() |> order_by(asc: :name)
  end

  def random(status, limit) when is_list(status) do
    status
    |> query()
    |> order_by([fragment("RANDOM()")])
    |> limit(^limit)
  end

  defp query(status) do
    from(c in ChallengeProjection, where: c.status in ^status)
  end
end
