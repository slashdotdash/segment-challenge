defmodule SegmentChallenge.Commands.LimitCompetitorParticipationInChallenge do
  defstruct [
    :challenge_uuid,
    :athlete_uuid,
    :reason,
  ]

  use Vex.Struct

  validates :challenge_uuid, uuid: true
  validates :athlete_uuid, uuid: true
  validates :reason, presence: true, string: true
end
