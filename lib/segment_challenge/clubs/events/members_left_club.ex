defmodule SegmentChallenge.Events.MembersLeftClub do
  @derive Jason.Encoder
  defstruct [
    club_uuid: nil,
    left_athlete_uuids: [],
  ]
end
