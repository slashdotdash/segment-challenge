defmodule SegmentChallenge.Projections.Profiles.ProfileProjectionTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.ImportAthleteUseCase
  import SegmentChallenge.UseCases.ImportClubUseCase

  alias SegmentChallenge.Wait

  alias SegmentChallenge.Events.{
    AthleteImported,
    ClubImported
  }

  alias SegmentChallenge.Projections.Profiles.ProfileProjection
  alias SegmentChallenge.Repo

  describe "importing a club" do
    setup [:import_club]

    @tag :integration
    @tag :projection
    test "should create club profile projection", context do
      wait_for_event(ClubImported, fn event -> event.club_uuid == context[:club_uuid] end)

      assert_profile(
        context[:club_uuid],
        "club",
        "https://example.com/pictures/clubs/large.jpg"
      )
    end
  end

  describe "importing an existing club but different profile image" do
    setup [:import_club, :import_club_different_profile]

    @tag :integration
    @tag :projection
    test "should update club projection", %{club_uuid: club_uuid} do
      assert_profile(
        club_uuid,
        "club",
        "https://example.com/pictures/clubs/edited.jpg"
      )
    end
  end

  describe "importing an athlete" do
    setup [:import_athlete]

    @tag :integration
    @tag :projection
    test "should create athlete profile projection", context do
      wait_for_event(AthleteImported, fn event -> event.athlete_uuid == context[:athlete_uuid] end)

      assert_profile(
        context[:athlete_uuid],
        "athlete",
        "https://example.com/pictures/athletes/large.jpg"
      )
    end
  end

  defp assert_profile(uuid, source, profile_url) do
    Wait.until(fn ->
      profile = Repo.get(ProfileProjection, uuid)

      assert profile != nil
      assert profile.source == source
      assert profile.source_uuid == uuid
      assert profile.profile == profile_url
    end)
  end
end
