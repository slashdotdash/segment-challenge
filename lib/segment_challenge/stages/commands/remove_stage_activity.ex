defmodule SegmentChallenge.Stages.Stage.Commands.RemoveStageActivity do
  defstruct [
    :stage_uuid,
    :strava_activity_id
  ]

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:strava_activity_id, presence: true, by: &is_integer/1)
end
