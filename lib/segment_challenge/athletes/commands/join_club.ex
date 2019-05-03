defmodule SegmentChallenge.Commands.JoinClub do
  defstruct [
    :athlete_uuid,
    :club_uuid,
  ]

  use Vex.Struct

  validates :athlete_uuid, uuid: true
  validates :club_uuid, uuid: true
end
