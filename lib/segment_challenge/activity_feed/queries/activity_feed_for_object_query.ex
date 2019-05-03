defmodule SegmentChallenge.Challenges.Queries.ActivityFeeds.ActivityFeedForObjectQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection

  def new(type, uuid) do
    from(a in ActivityProjection,
      where: a.object_type == ^type and a.object_uuid == ^uuid,
      order_by: [desc: a.published, desc: a.id]
    )
  end
end
