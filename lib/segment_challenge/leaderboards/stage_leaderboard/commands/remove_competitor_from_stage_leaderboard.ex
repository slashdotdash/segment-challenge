defmodule SegmentChallenge.Commands.RemoveCompetitorFromStageLeaderboard do
  defstruct [
    :stage_leaderboard_uuid,
    :athlete_uuid,
    :removed_at
  ]

  use Vex.Struct

  validates(:stage_leaderboard_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  validates(:removed_at, presence: true, naivedatetime: true)
end
