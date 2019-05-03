defmodule SegmentChallenge.Commands.RemoveStageFromChallenge do
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number
  ]

  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:stage_uuid, uuid: true)
end
