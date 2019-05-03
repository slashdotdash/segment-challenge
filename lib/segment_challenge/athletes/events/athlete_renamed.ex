defmodule SegmentChallenge.Events.AthleteRenamed do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :firstname,
    :lastname,
    :fullname,
  ]
end
