defmodule SegmentChallenge.Commands.AssignPointsFromStageLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :challenge_stage_uuids,
    :stage_uuid,
    :stage_type,
    :points_adjustment,
    :entries
  ]

  use Vex.Struct

  validates(:challenge_leaderboard_uuid, uuid: true)
  validates(:challenge_uuid, uuid: true)
  validates(:challenge_stage_uuids, by: [function: &is_list/1, allow_nil: false])
  validates(:stage_uuid, uuid: true)
  validates(:stage_type, stage_type: true)
  validates(:points_adjustment, pointsadjustment: true)
  validates(:entries, by: &is_list/1)
end
