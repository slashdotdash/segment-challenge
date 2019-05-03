defmodule SegmentChallenge.Stages.Stage.Commands.SetStageDescription do
  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :description,
    :updated_by_athlete_uuid
  ]

  use ExConstructor
  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:challenge_uuid, uuid: true)
  validates(:description, presence: true, string: true)
  validates(:updated_by_athlete_uuid, uuid: true)
end
