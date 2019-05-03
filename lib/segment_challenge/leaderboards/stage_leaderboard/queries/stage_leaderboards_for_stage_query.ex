defmodule SegmentChallenge.Challenges.Queries.Leaderboards.StageLeaderboardsForStageQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection

  def new(stage_uuid) do
    from(sl in StageLeaderboardProjection,
      where: sl.stage_uuid == ^stage_uuid,
      order_by: sl.name
    )
  end
end
