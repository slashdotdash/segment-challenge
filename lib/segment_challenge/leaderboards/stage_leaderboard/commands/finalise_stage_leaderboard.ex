defmodule SegmentChallenge.Commands.FinaliseStageLeaderboard do
  defstruct [
    :stage_leaderboard_uuid
  ]

  use Vex.Struct

  validates(:stage_leaderboard_uuid, uuid: true)
end
