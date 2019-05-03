defmodule SegmentChallenge.Events.MemberJoinedClub do
  @derive Jason.Encoder
  defstruct [
    :club_uuid,
    :athlete_uuid,
    :strava_id,
    :firstname,
    :lastname,
    :profile,
    :city,
    :state,
    :country,
    :gender,
  ]
end
