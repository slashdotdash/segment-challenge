defmodule SegmentChallenge.Commands.SetChallengeDescription do
  defstruct [
    :challenge_uuid,
    :description,
    :updated_by_athlete_uuid,
  ]

  use ExConstructor
  use Vex.Struct

  validates :challenge_uuid, uuid: true
  validates :description, presence: true, string: true
  validates :updated_by_athlete_uuid, uuid: true
end
