defmodule SegmentChallenge.Clubs.ImportClubTest do
  use SegmentChallenge.StorageCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.Factory

  alias SegmentChallenge.Events.ClubImported
  alias SegmentChallenge.Router

  @tag :integration
  test "import club" do
    strava_id = 7289
    club_uuid = UUID.uuid4()

    :ok = Router.dispatch(build(:import_club, club_uuid: club_uuid, strava_id: strava_id))

    assert_receive_event(ClubImported, fn event ->
      assert event.club_uuid == club_uuid
      assert event.strava_id == strava_id
      assert event.name == "VC Venta"
    end)
  end
end
