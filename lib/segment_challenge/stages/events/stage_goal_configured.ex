defmodule SegmentChallenge.Events.StageGoalConfigured do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :goal,
    :goal_measure,
    :goal_units
  ]
end
