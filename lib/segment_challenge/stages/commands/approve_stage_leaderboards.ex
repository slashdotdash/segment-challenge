defmodule SegmentChallenge.Stages.Stage.Commands.ApproveStageLeaderboards do
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :approved_by_athlete_uuid,
    :approved_by_club_uuid,
    :approval_message
  ]

  use ExConstructor
  use Vex.Struct

  alias SegmentChallenge.Stages.Validators.ApproveStageLeaderboards

  validates(:challenge_uuid, uuid: true)
  validates(:stage_uuid, uuid: true)
  validates(:approved_by_athlete_uuid, uuid: true)
  validates(:approved_by_club_uuid, uuid: true)
  validates(:approval_message, string: true, by: &ApproveStageLeaderboards.validate/2)
end
