defmodule SegmentChallenge.Commands.LeaveClub do
  defstruct [
    :athlete_uuid,
    :club_uuid,
  ]

  use Vex.Struct

  validates :athlete_uuid, presence: true
  validates :club_uuid, presence: true
end
