defmodule SegmentChallenge.Challenges.Queries.Leaderboards.ChallengeLeaderboardQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ChallengeLeaderboardProjection

  def new(challenge_uuid) do
  	from cl in ChallengeLeaderboardProjection,
  	where: cl.challenge_uuid == ^challenge_uuid,
    order_by: [asc: cl.name, desc: cl.gender]
  end
end
