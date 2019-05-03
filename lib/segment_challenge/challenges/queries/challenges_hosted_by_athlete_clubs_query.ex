defmodule SegmentChallenge.Challenges.Queries.Challenges.ChallengesHostedByAthleteClubsQuery do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Projections.Clubs.AthleteClubMembershipProjection
  alias SegmentChallenge.Projections.ChallengeProjection

  def new(athlete_uuid, status \\ ["upcoming", "active", "past"])

  def new(athlete_uuid, status) do
    from(c in ChallengeProjection,
      join: acm in AthleteClubMembershipProjection,
      on: acm.club_uuid == c.hosted_by_club_uuid,
      where: acm.athlete_uuid == ^athlete_uuid and c.status in ^status,
      order_by: [desc: c.start_date_local]
    )
  end
end
