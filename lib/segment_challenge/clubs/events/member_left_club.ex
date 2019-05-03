defmodule SegmentChallenge.Events.MemberLeftClub do
  @derive Jason.Encoder
  defstruct [
    :club_uuid,
    :athlete_uuid,
    :strava_id,
    :firstname,
    :lastname,
  ]
end
