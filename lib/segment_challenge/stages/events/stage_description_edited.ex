defmodule SegmentChallenge.Events.StageDescriptionEdited do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :description,
    :updated_by_athlete_uuid
  ]
end
