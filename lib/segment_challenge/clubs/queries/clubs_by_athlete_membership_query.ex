defmodule SegmentChallenge.Challenges.Queries.Clubs.ClubsByAthleteMembershipQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.Clubs.{
    AthleteClubMembershipProjection,
    ClubProjection,
  }

  def new(athlete_uuid) do
  	from c in ClubProjection,
    join: m in AthleteClubMembershipProjection,
  	where: c.club_uuid == m.club_uuid and m.athlete_uuid == ^athlete_uuid,
    order_by: c.name
  end
end
