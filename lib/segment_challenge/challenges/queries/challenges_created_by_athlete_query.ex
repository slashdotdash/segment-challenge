defmodule SegmentChallenge.Challenges.Queries.Challenges.ChallengesCreatedByAthleteQuery do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Projections.ChallengeProjection

  def new(athlete_uuid) do
    from(c in ChallengeProjection,
      where: c.created_by_athlete_uuid == ^athlete_uuid,
      order_by: [desc: c.start_date_local]
    )
  end
end
