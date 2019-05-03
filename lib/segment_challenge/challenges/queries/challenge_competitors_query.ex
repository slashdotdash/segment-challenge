defmodule SegmentChallenge.Challenges.Queries.Challenges.ChallengeCompetitorsQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ChallengeCompetitorProjection

  def new(challenge_uuid) do
    from(c in ChallengeCompetitorProjection, where: c.challenge_uuid == ^challenge_uuid)
  end
end
