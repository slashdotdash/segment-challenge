defmodule SegmentChallenge.Events.AthleteProfileChanged do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :profile,
  ]
end
