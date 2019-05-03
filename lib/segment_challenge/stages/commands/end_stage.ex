defmodule SegmentChallenge.Stages.Stage.Commands.EndStage do
  defstruct [
    :stage_uuid
  ]

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
end
