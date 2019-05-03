defmodule SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery do
  import Ecto.Query, only: [from: 2]
  
  alias SegmentChallenge.Projections.StageProjection

  def new(challenge_uuid) do
  	from s in StageProjection,
  	where: s.challenge_uuid == ^challenge_uuid,
    order_by: s.stage_number
  end
end
