defmodule SegmentChallenge.Stages.Stage.Commands.RevealStage do
  defstruct [
    :challenge_uuid,
    :stage_uuid
  ]

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:stage_uuid, uuid: true)
end
