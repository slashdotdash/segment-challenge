defmodule SegmentChallenge.Challenges.Queries.Leaderboards.ChallengeLeaderboardEntriesQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ChallengeLeaderboardEntryProjection

  def new(challenge_leaderboard_uuid) do
  	from e in ChallengeLeaderboardEntryProjection,
  	where: e.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid,
    order_by: [e.rank, e.athlete_lastname]
  end
end
