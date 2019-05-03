defmodule SegmentChallenge.Challenges.Queries.Stages.StageBySlugQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.StageProjection

  def new(challenge_uuid, url_slug) do
    from(s in StageProjection,
      where: s.challenge_uuid == ^challenge_uuid and s.url_slug == ^url_slug
    )
  end
end
