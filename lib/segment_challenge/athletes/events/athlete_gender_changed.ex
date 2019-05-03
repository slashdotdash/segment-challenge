defmodule SegmentChallenge.Events.AthleteGenderChanged do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :gender
  ]
end
