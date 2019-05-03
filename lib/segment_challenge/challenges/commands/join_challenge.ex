defmodule SegmentChallenge.Commands.JoinChallenge do
  defstruct [
    :challenge_uuid,
    :athlete_uuid,
    :gender
  ]

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  # Gender is optional (it may be `nil`)
  validates(:gender, gender: true)
end
