defmodule SegmentChallenge.Challenges.Queries.Leaderboards.StageResultQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.StageResultProjection

  def new(stage_uuid) do
    from(sr in StageResultProjection,
      where: sr.stage_uuid == ^stage_uuid and not is_nil(sr.challenge_leaderboard_uuid),
      order_by: [asc: sr.name, desc: sr.gender]
    )
  end
end
