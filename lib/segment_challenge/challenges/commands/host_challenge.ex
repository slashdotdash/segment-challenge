defmodule SegmentChallenge.Commands.HostChallenge do
  defstruct [
    :challenge_uuid,
    :hosted_by_athlete_uuid
  ]

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:hosted_by_athlete_uuid, uuid: true)
end
