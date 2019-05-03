defmodule SegmentChallenge.Commands.SetAthleteClubMemberships do
  defstruct [
    athlete_uuid: :nil,
    club_uuids: [],
  ]

  use Vex.Struct

  validates :athlete_uuid, uuid: true
end
