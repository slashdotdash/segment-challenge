defmodule SegmentChallenge.Events.ChallengeDescriptionEdited do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :description,
    :updated_by_athlete_uuid,
  ]
end
