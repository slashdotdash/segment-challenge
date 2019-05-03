defmodule SegmentChallenge.Challenges.Queries.Challenges.ChallengesEnteredByAthleteQuery do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Projections.ChallengeCompetitorProjection
  alias SegmentChallenge.Projections.ChallengeProjection

  def new(athlete_uuid, status \\ ["upcoming", "active", "past"]) do
    from(c in ChallengeProjection,
      join: cc in ChallengeCompetitorProjection,
      on: cc.challenge_uuid == c.challenge_uuid,
      where: cc.athlete_uuid == ^athlete_uuid and c.status in ^status,
      order_by: [desc: c.start_date_local]
    )
  end
end
