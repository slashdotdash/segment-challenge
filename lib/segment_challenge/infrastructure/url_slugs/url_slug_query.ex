defmodule SegmentChallenge.Projections.Slugs.UrlSlugQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.Slugs.UrlSlugProjection

  def new(source, slug) do
    from s in UrlSlugProjection,
    where: s.source == ^source and s.slug == ^slug
  end
end
