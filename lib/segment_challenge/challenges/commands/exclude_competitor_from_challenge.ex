defmodule SegmentChallenge.Commands.ExcludeCompetitorFromChallenge do
  defstruct [
    :challenge_uuid,
    :athlete_uuid,
    :reason,
    :excluded_at,
  ]

  use Vex.Struct

  validates :challenge_uuid, uuid: true
  validates :athlete_uuid, uuid: true
  validates :reason, presence: true, string: true
  validates :excluded_at, presence: true, naivedatetime: true
end
