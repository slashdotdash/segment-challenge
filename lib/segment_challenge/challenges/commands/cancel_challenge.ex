defmodule SegmentChallenge.Commands.CancelChallenge do
  defstruct [
    :challenge_uuid,
    :cancelled_by_athlete_uuid
  ]

  use ExConstructor
  use Vex.Struct

  validates :challenge_uuid, uuid: true
  validates :cancelled_by_athlete_uuid, uuid: true
end
