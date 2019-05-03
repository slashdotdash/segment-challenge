defmodule SegmentChallenge.Events.ClubImported do
  @derive Jason.Encoder
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
    :website,
    :private
  ]
end
