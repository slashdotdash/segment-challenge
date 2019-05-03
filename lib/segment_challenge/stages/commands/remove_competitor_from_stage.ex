defmodule SegmentChallenge.Stages.Stage.Commands.RemoveCompetitorFromStage do
  defstruct [
    :stage_uuid,
    :athlete_uuid,
    :removed_at
  ]

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  validates(:removed_at, naivedatetime: true)
end
