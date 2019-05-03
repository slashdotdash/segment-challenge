defmodule SegmentChallenge.Events.StageIncludedActivitiesAdjusted do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :included_activity_types
  ]
end
