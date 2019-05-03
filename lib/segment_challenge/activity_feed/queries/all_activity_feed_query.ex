defmodule SegmentChallenge.Challenges.Queries.ActivityFeeds.AllActivityFeedQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection

  def new(limit) do
  	from a in ActivityProjection,
  	order_by: [desc: a.published, desc: a.id],
    limit: ^limit
  end
end
