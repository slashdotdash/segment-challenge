defmodule SegmentChallenge.Stages.Stage.Commands.DeleteStage do
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :deleted_by_athlete_uuid
  ]

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:stage_uuid, uuid: true)
  validates(:deleted_by_athlete_uuid, uuid: true)
end
