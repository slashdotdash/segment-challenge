defmodule SegmentChallenge.Challenges.Queries.Stages.StageEffortsQuery do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Projections.StageEffortProjection

  def new(athlete_uuid: athlete_uuid, stage_uuid: stage_uuid) do
    from(se in StageEffortProjection,
      where: se.stage_uuid == ^stage_uuid and se.athlete_uuid == ^athlete_uuid,
      order_by: [asc: se.start_date]
    )
  end
end
