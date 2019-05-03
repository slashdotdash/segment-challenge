defmodule SegmentChallenge.Stages.Stage.Commands.ConfigureAthleteGenderInStage do
  defstruct [
    :stage_uuid,
    :athlete_uuid,
    :gender
  ]

  use ExConstructor
  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  validates(:gender, gender: true)
end
