defmodule SegmentChallenge.Commands.AdjustPointsFromStageLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :challenge_stage_uuids,
    :stage_uuid,
    :stage_type,
    :points_adjustment,
    :previous_entries,
    :adjusted_entries
  ]

  use Vex.Struct

  validates(:challenge_leaderboard_uuid, uuid: true)
  validates(:challenge_uuid, uuid: true)
  validates(:challenge_stage_uuids, presence: true, by: &is_list/1)
  validates(:stage_uuid, uuid: true)
  validates(:stage_type, stage_type: true)
  validates(:points_adjustment, pointsadjustment: true)
  validates(:previous_entries, by: &is_list/1)
  validates(:adjusted_entries, by: &is_list/1)
end
