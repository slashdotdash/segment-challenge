defmodule SegmentChallenge.Athletes.Queries.AthleteBadgesQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Athletes.Projections.BadgeProjection

  def new(athlete_uuid) do
    from(b in BadgeProjection,
      where: b.athlete_uuid == ^athlete_uuid,
      order_by: [desc: b.earned_at]
    )
  end
end
