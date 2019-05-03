defmodule SegmentChallenge.Commands.AllowCompetitorParticipationInChallenge do
  defstruct [
    :challenge_uuid,
    :athlete_uuid
  ]

  use Vex.Struct

  validates :challenge_uuid, uuid: true
  validates :athlete_uuid, uuid: true
end
