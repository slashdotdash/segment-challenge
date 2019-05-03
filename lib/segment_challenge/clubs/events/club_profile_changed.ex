defmodule SegmentChallenge.Events.ClubProfileChanged do
  @derive Jason.Encoder
  defstruct [
    :club_uuid,
    :strava_id,
    :profile,
  ]
end
