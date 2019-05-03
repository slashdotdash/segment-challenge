defmodule SegmentChallenge.Challenges.Queries.Profiles.ProfileQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.Profiles.ProfileProjection

  def new(source, source_uuid) do
  	from p in ProfileProjection,
  	where: p.source == ^source and p.source_uuid == ^source_uuid
  end
end
