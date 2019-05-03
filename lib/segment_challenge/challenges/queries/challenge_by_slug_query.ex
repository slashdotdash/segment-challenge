defmodule SegmentChallenge.Challenges.Queries.Challenges.ChallengeBySlugQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ChallengeProjection

  def new(url_slug) do
  	from c in ChallengeProjection,
  	where: c.url_slug == ^url_slug
  end
end
