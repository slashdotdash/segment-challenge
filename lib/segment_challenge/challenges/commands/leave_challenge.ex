defmodule SegmentChallenge.Commands.LeaveChallenge do
  defstruct [
    :challenge_uuid,
    :athlete_uuid
  ]

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
end
