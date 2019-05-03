defmodule SegmentChallenge.Events.AthleteEmailChanged do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :email
  ]
end
