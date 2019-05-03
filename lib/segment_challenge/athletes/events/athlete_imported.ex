defmodule SegmentChallenge.Events.AthleteImported do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :strava_id,
    :firstname,
    :lastname,
    :fullname,
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
end
