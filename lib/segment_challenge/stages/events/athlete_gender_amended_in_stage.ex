defmodule SegmentChallenge.Events.AthleteGenderAmendedInStage do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :athlete_uuid,
    :gender,
  ]
end
