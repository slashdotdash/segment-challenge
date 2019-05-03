defmodule SegmentChallenge.Commands.ImportClub do
  defstruct [
    :club_uuid,
    :strava_id,
    :name,
    :description,
    :sport_type,
    :city,
    :state,
    :country,
    :profile,
    :private
  ]

  use Vex.Struct

  validates(:club_uuid, uuid: true)
  validates(:strava_id, presence: true, by: &is_integer/1)
  validates(:name, presence: true, string: true)
  validates(:description, string: true)
  validates(:sport_type, string: true)
  validates(:city, string: true)
  validates(:state, string: true)
  validates(:country, string: true)
  validates(:profile, string: true)
  validates(:private, by: &is_boolean/1)
end
