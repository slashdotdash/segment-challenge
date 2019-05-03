defmodule SegmentChallenge.Events.AthleteJoinedClub do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :club_uuid,
    :firstname,
    :lastname,
    :gender,
  ]
end
