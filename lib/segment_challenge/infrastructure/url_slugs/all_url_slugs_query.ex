defmodule SegmentChallenge.Projections.Slugs.AllUrlSlugsQuery do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Projections.Slugs.UrlSlugProjection

  def new do
    from s in UrlSlugProjection,
    select: {s.source, s.source_uuid, s.slug}
  end
end
