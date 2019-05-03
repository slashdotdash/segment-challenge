defmodule SegmentChallenge.Clubs.ClubTest do
  use ExUnit.Case

  import SegmentChallenge.Factory
  import SegmentChallenge.Aggregate, only: [evolve: 2]

  alias SegmentChallenge.Events.{ClubImported, ClubProfileChanged}
  alias SegmentChallenge.Clubs.Club

  @tag :unit
  test "import club" do
    club_uuid = UUID.uuid4()

    club_imported = import_club(club_uuid)

    assert club_imported == %ClubImported{
             club_uuid: club_uuid,
             strava_id: 7289,
             name: "VC Venta",
             description:
               "Friendly cycling club in Winchester for those interested in cycling of all kinds.",
             sport_type: "cycling",
             city: "Winchester",
             state: "England",
             country: "United Kingdom",
             profile: "https://example.com/pictures/clubs/large.jpg",
             private: false
           }
  end

  @tag :unit
  test "import existing club but changed profile image" do
    club_uuid = UUID.uuid4()
    profile = "https://example.com/pictures/clubs/edited.jpg"

    event =
      with club <- evolve(%Club{}, import_club(club_uuid)),
           do: Club.execute(club, build(:import_club, club_uuid: club_uuid, profile: profile))

    assert event == %ClubProfileChanged{
             club_uuid: club_uuid,
             strava_id: 7289,
             profile: profile
           }
  end

  defp import_club(club_uuid) do
    Club.execute(%Club{}, build(:import_club, club_uuid: club_uuid))
  end
end
