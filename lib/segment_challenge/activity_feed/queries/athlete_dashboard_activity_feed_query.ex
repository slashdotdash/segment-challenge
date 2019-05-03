defmodule SegmentChallenge.Challenges.Queries.ActivityFeeds.AthleteDashboardActivityFeedQuery do
  import Ecto.Query

  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection

  # Include activity from joined challenges and athlete's activity
  def new(athlete_uuid, challenges) do
    from(a in ActivityProjection,
      where:
        (a.actor_type == "challenge" and a.actor_uuid in ^challenges) or
          (a.actor_type == "athlete" and a.actor_uuid == ^athlete_uuid),
      order_by: [desc: a.published, desc: a.id]
    )
  end
end
