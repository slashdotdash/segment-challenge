defmodule SegmentChallenge.Events.StageDeleted do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
    :deleted_by_athlete_uuid
  ]
end
