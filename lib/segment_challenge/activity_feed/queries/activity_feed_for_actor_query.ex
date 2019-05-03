defmodule SegmentChallenge.Challenges.Queries.ActivityFeeds.ActivityFeedForActorQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection

  @default_limit 20

  def new(type, uuid) do
  	from a in ActivityProjection,
  	where: a.actor_type == ^type and a.actor_uuid == ^uuid,
    order_by: [desc: a.published, desc: a.id],
    limit: ^@default_limit
  end

  def new(type, uuid, before, id) do
  	from a in new(type, uuid),
    where: a.published <= ^before and a.id < ^id
  end
end
