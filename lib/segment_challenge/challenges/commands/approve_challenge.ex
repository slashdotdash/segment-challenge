defmodule SegmentChallenge.Commands.ApproveChallenge do
  defstruct [
    :challenge_uuid,
    :approved_by_athlete_uuid,
    :approved_at
  ]

  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:approved_by_athlete_uuid, uuid: true)
  validates(:approved_at, presence: true, naivedatetime: true)
end
