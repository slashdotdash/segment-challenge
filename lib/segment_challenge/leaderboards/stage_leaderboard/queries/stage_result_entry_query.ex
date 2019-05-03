defmodule SegmentChallenge.Challenges.Queries.Leaderboards.StageResultEntryQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.StageResultEntryProjection

  def new(challenge_leaderboard_uuid, stage_uuid) do
    from(e in StageResultEntryProjection,
      where:
        e.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid and
          e.stage_uuid == ^stage_uuid,
      order_by: [asc: e.rank, asc: e.athlete_lastname]
    )
  end
end
