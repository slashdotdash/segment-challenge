defmodule SegmentChallenge.Events.CompetitorRemovedFromStage do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :athlete_uuid,
    :removed_at,
    attempt_count: 0,
    competitor_count: 0
  ]
end
