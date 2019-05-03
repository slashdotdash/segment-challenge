defmodule SegmentChallenge.Stages.Stage.Commands.PublishStageResults do
  defstruct [
    :stage_uuid,
    :published_by_athlete_uuid,
    :published_by_club_uuid,
    :message
  ]

  use ExConstructor
  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:published_by_athlete_uuid, uuid: true)
  validates(:published_by_club_uuid, uuid: true)
  validates(:message, string: true, presence: true)
end
