defmodule SegmentChallenge.Stages.Stage.Commands.ChangeStageSegment do
  defstruct [
    :stage_uuid,
    :strava_segment_id
  ]

  use ExConstructor
  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:strava_segment_id, presence: true, by: &is_integer/1)
end
