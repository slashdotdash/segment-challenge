defmodule SegmentChallenge.Commands.IncludeStageInChallenge do
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
    :name,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
  ]

  use Vex.Struct

  validates :challenge_uuid, uuid: true
  validates :stage_uuid, uuid: true
  validates :name, presence: true, string: true
  validates :start_date, presence: true, naivedatetime: true
  validates :start_date_local, presence: true, naivedatetime: true
  validates :end_date, presence: true, naivedatetime: true
  validates :end_date_local, presence: true, naivedatetime: true
end
