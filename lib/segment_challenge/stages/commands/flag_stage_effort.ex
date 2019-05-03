defmodule SegmentChallenge.Stages.Stage.Commands.FlagStageEffort do
  defstruct [
    :stage_uuid,
    :strava_activity_id,
    :strava_segment_effort_id,
    :flagged_by_athlete_uuid,
    :reason
  ]

  use ExConstructor
  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:strava_activity_id, by: [function: &is_integer/1, allow_nil: true])
  validates(:strava_segment_effort_id, by: [function: &is_integer/1, allow_nil: true])
  validates(:flagged_by_athlete_uuid, uuid: true)
  validates(:reason, presence: true, string: true)
end
