defmodule SegmentChallenge.Stages.Stage.Guards do
  defguard is_active_stage(status) when status in [:pending, :active]

  defguard is_activity_stage(stage_type) when stage_type in ["distance", "duration", "elevation"]

  defguard is_segment_stage(stage_type) when stage_type in ["mountain", "flat", "rolling"]

  defguard is_race_stage(stage_type) when stage_type == "race"
end
