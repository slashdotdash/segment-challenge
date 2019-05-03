defmodule SegmentChallenge.Challenges.Queries.Leaderboards.StageLeaderboardEntriesQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardEntryProjection

  def new(stage_leaderboard_uuid) do
    from(e in StageLeaderboardEntryProjection,
      where: e.stage_leaderboard_uuid == ^stage_leaderboard_uuid,
      order_by: [e.rank, e.start_date_local]
    )
  end
end
