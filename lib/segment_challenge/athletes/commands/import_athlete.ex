defmodule SegmentChallenge.Commands.ImportAthlete do
  defstruct [
    :athlete_uuid,
    :strava_id,
    :firstname,
    :lastname,
    :profile,
    :city,
    :state,
    :country,
    :gender,
    :date_preference,
    :measurement_preference,
    :email,
    :ftp,
    :weight,
  ]

  use Vex.Struct

  validates :athlete_uuid, uuid: true
  validates :strava_id, presence: true, by: &is_integer(&1)
  validates :firstname, presence: true, string: true
  validates :lastname, presence: true, string: true
  validates :gender, gender: true  # optional, may be nil
end
