defmodule SegmentChallenge.Challenges.Queries.Clubs.ClubMemberQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.Clubs.AthleteClubMembershipProjection

  def new(club_uuid, athlete_uuid) do
    from(
      m in AthleteClubMembershipProjection,
      where: m.club_uuid == ^club_uuid and m.athlete_uuid == ^athlete_uuid
    )
  end
end
