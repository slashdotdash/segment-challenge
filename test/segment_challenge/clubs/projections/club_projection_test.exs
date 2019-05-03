defmodule SegmentChallenge.Projections.ClubProjectionTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.ImportAthleteUseCase
  import SegmentChallenge.UseCases.ImportClubUseCase
  import Ecto.Query

  alias SegmentChallenge.Wait

  alias SegmentChallenge.Events.{
    AthleteJoinedClub,
    AthleteLeftClub,
    ClubImported,
    ClubProfileChanged
  }

  alias SegmentChallenge.Repo

  alias SegmentChallenge.Projections.Clubs.{
    ClubProjection,
    AthleteClubMembershipProjection
  }

  describe "importing a club" do
    setup [:import_club]

    @tag :integration
    @tag :projection
    test "should create club projection", context do
      wait_for_event(ClubImported, fn event -> event.club_uuid == context[:club_uuid] end)

      Wait.until(fn ->
        club = Repo.get(ClubProjection, context[:club_uuid])

        assert club != nil
        assert club.name == "VC Venta"

        assert club.profile ==
                 "https://example.com/pictures/clubs/large.jpg"

        assert club.last_imported_at == nil
        assert club.private == false
      end)
    end
  end

  describe "importing a private club" do
    setup [:import_private_club]

    @tag :integration
    @tag :projection
    test "should create club projection", context do
      wait_for_event(ClubImported, fn event -> event.club_uuid == context[:club_uuid] end)

      Wait.until(fn ->
        club = Repo.get(ClubProjection, context[:club_uuid])

        assert club != nil
        assert club.name == "VC Venta"

        assert club.profile ==
                 "https://example.com/pictures/clubs/large.jpg"

        assert club.last_imported_at == nil
        assert club.private == true
      end)
    end
  end

  describe "importing an existing club but different profile image" do
    setup [:import_club, :import_club_different_profile]

    @tag :integration
    @tag :projection
    test "should create club projection", context do
      wait_for_event(ClubProfileChanged, fn event -> event.club_uuid == context[:club_uuid] end)

      Wait.until(fn ->
        club = Repo.get(ClubProjection, context[:club_uuid])

        assert club != nil
        assert club.name == "VC Venta"

        assert club.profile ==
                 "https://example.com/pictures/clubs/edited.jpg"
      end)
    end
  end

  describe "athlete imported with club memberships" do
    setup [:import_athlete, :import_club, :set_athlete_club_memberships]

    @tag :integration
    @tag :projection
    test "should create athlete club membership", context do
      wait_for_event(AthleteJoinedClub, fn event ->
        event.athlete_uuid == context[:athlete_uuid]
      end)

      Wait.until(fn ->
        membership =
          athlete_club_membership_query(context[:athlete_uuid], context[:club_uuid]) |> Repo.one()

        assert membership != nil
        assert membership.athlete_uuid == context[:athlete_uuid]
        assert membership.club_uuid == context[:club_uuid]
      end)
    end
  end

  describe "athlete imported with fewer club memberships" do
    setup [
      :import_athlete,
      :import_club,
      :set_athlete_club_memberships,
      :set_athlete_empty_club_memberships
    ]

    @tag :integration
    @tag :projection
    test "should remove athlete club membership", context do
      wait_for_event(AthleteLeftClub, fn event -> event.athlete_uuid == context[:athlete_uuid] end)

      Wait.until(fn ->
        membership =
          athlete_club_membership_query(context[:athlete_uuid], context[:club_uuid]) |> Repo.one()

        assert membership == nil
      end)
    end
  end

  defp athlete_club_membership_query(athlete_uuid, club_uuid) do
    from(m in AthleteClubMembershipProjection,
      where: m.athlete_uuid == ^athlete_uuid and m.club_uuid == ^club_uuid
    )
  end
end
