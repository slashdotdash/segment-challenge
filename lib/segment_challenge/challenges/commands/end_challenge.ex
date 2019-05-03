defmodule SegmentChallenge.Commands.EndChallenge do
  defstruct [
    :challenge_uuid,
  ]

  use Vex.Struct

  validates :challenge_uuid, uuid: true
end
