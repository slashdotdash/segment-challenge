defmodule SegmentChallenge.Events.AthleteLeftClub do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :club_uuid,
  ]
end
