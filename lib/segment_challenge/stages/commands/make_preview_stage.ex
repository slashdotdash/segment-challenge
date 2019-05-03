defmodule SegmentChallenge.Stages.Stage.Commands.MakePreviewStage do
  defstruct [
    :stage_uuid
  ]

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
end
