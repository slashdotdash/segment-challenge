defmodule SegmentChallenge.Events.MembersJoinedClub do
  defmodule Member do
    @derive Jason.Encoder
    defstruct [
      :athlete_uuid,
      :strava_id,
      :firstname,
      :lastname,
      :profile,
      :city,
      :state,
      :country,
      :gender
    ]
  end

  @derive Jason.Encoder
  defstruct [:club_uuid, members: []]
end
