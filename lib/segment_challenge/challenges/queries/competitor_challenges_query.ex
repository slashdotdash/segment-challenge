defmodule SegmentChallenge.Challenges.Queries.Challenges.CompetitorChallengesQuery do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Projections.ChallengeCompetitorProjection

  def new(athlete_uuid) do
    from(cc in ChallengeCompetitorProjection,
      where: cc.athlete_uuid == ^athlete_uuid,
      select: cc.challenge_uuid
    )
  end
end
