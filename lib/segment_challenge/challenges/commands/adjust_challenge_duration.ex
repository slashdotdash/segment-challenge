defmodule SegmentChallenge.Commands.AdjustChallengeDuration do
  defstruct [
    :challenge_uuid,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
  ]

  use ExConstructor
  use Vex.Struct

  validates :challenge_uuid, uuid: true
  validates :start_date, presence: true, naivedatetime: true
  validates :start_date_local, presence: true, naivedatetime: true
  validates :end_date, presence: true, naivedatetime: true
  validates :end_date_local, presence: true, naivedatetime: true
end
