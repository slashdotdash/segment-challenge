defmodule SegmentChallenge.Athletes.AthleteTest do
  use ExUnit.Case

  import SegmentChallenge.Factory

  alias SegmentChallenge.Commands.{
    ImportAthlete,
    JoinClub,
    LeaveClub,
    SetAthleteClubMemberships
  }

  alias SegmentChallenge.Events.{
    AthleteEmailChanged,
    AthleteGenderChanged,
    AthleteImported,
    AthleteJoinedClub,
    AthleteLeftClub,
    AthleteProfileChanged,
    AthleteRenamed,
    AthleteStarredStravaSegment,
    AthleteUnstarredStravaSegment
  }

  alias SegmentChallenge.Athletes.Athlete

  describe "import athlete" do
    @tag :unit
    test "should import new athlete" do
      athlete_uuid = UUID.uuid4()

      athlete_imported = import_example_athlete(athlete_uuid)

      assert athlete_imported ==
               struct(
                 AthleteImported,
                 build(:athlete, %{athlete_uuid: athlete_uuid, fullname: "Ben Smith", gender: "M"})
               )
    end

    @tag :unit
    test "should ignore existing athlete" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             do:
               Athlete.import_athlete(
                 athlete,
                 struct(
                   ImportAthlete,
                   build(:athlete, %{athlete_uuid: athlete_uuid, gender: "M"})
                 )
               )

      assert events == []
    end

    @tag :unit
    test "should rename existing athlete when name has changed" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             do:
               Athlete.import_athlete(
                 athlete,
                 struct(
                   ImportAthlete,
                   build(:athlete, %{
                     athlete_uuid: athlete_uuid,
                     gender: "M",
                     firstname: "Renamed",
                     lastname: "Athlete"
                   })
                 )
               )

      assert events == [
               %AthleteRenamed{
                 athlete_uuid: athlete_uuid,
                 firstname: "Renamed",
                 lastname: "Athlete",
                 fullname: "Renamed Athlete"
               }
             ]
    end

    @tag :unit
    test "should update athlete's email when changed" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             do:
               Athlete.import_athlete(
                 athlete,
                 struct(
                   ImportAthlete,
                   build(:athlete, %{
                     athlete_uuid: athlete_uuid,
                     gender: "M",
                     email: "updated@segmentchallenge.com"
                   })
                 )
               )

      assert events == [
               %AthleteEmailChanged{
                 athlete_uuid: athlete_uuid,
                 email: "updated@segmentchallenge.com"
               }
             ]
    end

    @tag :unit
    test "should update athlete's profile when changed" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             do:
               Athlete.import_athlete(
                 athlete,
                 struct(
                   ImportAthlete,
                   build(:athlete, %{
                     athlete_uuid: athlete_uuid,
                     gender: "M",
                     profile: "https://example.com/updated.jpg"
                   })
                 )
               )

      assert events == [
               %AthleteProfileChanged{
                 athlete_uuid: athlete_uuid,
                 profile: "https://example.com/updated.jpg"
               }
             ]
    end

    @tag :unit
    test "should update athlete's gender when changed" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid, %{gender: nil})),
             do:
               Athlete.import_athlete(
                 athlete,
                 struct(
                   ImportAthlete,
                   build(:athlete, %{athlete_uuid: athlete_uuid, gender: "M"})
                 )
               )

      assert events == [
               %AthleteGenderChanged{
                 athlete_uuid: athlete_uuid,
                 gender: "M"
               }
             ]
    end
  end

  describe "club membership" do
    @tag :unit
    test "join a club" do
      athlete_uuid = UUID.uuid4()
      club_uuid = UUID.uuid4()

      joined_club =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             do:
               Athlete.join_club(athlete, %JoinClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club_uuid
               })

      assert joined_club == %AthleteJoinedClub{
               athlete_uuid: athlete_uuid,
               club_uuid: club_uuid,
               firstname: "Ben",
               lastname: "Smith",
               gender: "M"
             }
    end

    @tag :unit
    test "join a club when already a member" do
      athlete_uuid = UUID.uuid4()
      club_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             athlete <-
               evolve(
                 athlete,
                 Athlete.join_club(athlete, %JoinClub{
                   athlete_uuid: athlete_uuid,
                   club_uuid: club_uuid
                 })
               ),
             do:
               Athlete.join_club(athlete, %JoinClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club_uuid
               })

      assert events == []
    end

    @tag :unit
    test "leave a club" do
      athlete_uuid = UUID.uuid4()
      club_uuid = UUID.uuid4()

      left_club =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             athlete <-
               evolve(
                 athlete,
                 Athlete.join_club(athlete, %JoinClub{
                   athlete_uuid: athlete_uuid,
                   club_uuid: club_uuid
                 })
               ),
             do:
               Athlete.leave_club(athlete, %LeaveClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club_uuid
               })

      assert left_club == %AthleteLeftClub{athlete_uuid: athlete_uuid, club_uuid: club_uuid}
    end

    @tag :unit
    test "leave a club when not a member" do
      athlete_uuid = UUID.uuid4()
      club_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             athlete <-
               evolve(
                 athlete,
                 Athlete.join_club(athlete, %JoinClub{
                   athlete_uuid: athlete_uuid,
                   club_uuid: club_uuid
                 })
               ),
             athlete <-
               evolve(
                 athlete,
                 Athlete.leave_club(athlete, %LeaveClub{
                   athlete_uuid: athlete_uuid,
                   club_uuid: club_uuid
                 })
               ),
             do:
               Athlete.leave_club(athlete, %LeaveClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club_uuid
               })

      assert events == []
    end

    @tag :unit
    test "set club memberships" do
      athlete_uuid = UUID.uuid4()
      club1_uuid = UUID.uuid4()
      club2_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             do:
               Athlete.set_club_memberships(athlete, %SetAthleteClubMemberships{
                 athlete_uuid: athlete_uuid,
                 club_uuids: [club1_uuid, club2_uuid]
               })

      assert events == [
               %AthleteJoinedClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club1_uuid,
                 firstname: "Ben",
                 lastname: "Smith",
                 gender: "M"
               },
               %AthleteJoinedClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club2_uuid,
                 firstname: "Ben",
                 lastname: "Smith",
                 gender: "M"
               }
             ]
    end

    @tag :unit
    test "set club memberships when already a member" do
      athlete_uuid = UUID.uuid4()
      club1_uuid = UUID.uuid4()
      club2_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             athlete <-
               evolve(
                 athlete,
                 Athlete.join_club(athlete, %JoinClub{
                   athlete_uuid: athlete_uuid,
                   club_uuid: club1_uuid
                 })
               ),
             do:
               Athlete.set_club_memberships(athlete, %SetAthleteClubMemberships{
                 athlete_uuid: athlete_uuid,
                 club_uuids: [club1_uuid, club2_uuid]
               })

      assert events == [
               %AthleteJoinedClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club2_uuid,
                 firstname: "Ben",
                 lastname: "Smith",
                 gender: "M"
               }
             ]
    end

    @tag :unit
    test "set club memberships when a member of another club" do
      athlete_uuid = UUID.uuid4()
      club1_uuid = UUID.uuid4()
      club2_uuid = UUID.uuid4()
      club3_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             athlete <-
               evolve(
                 athlete,
                 Athlete.join_club(athlete, %JoinClub{
                   athlete_uuid: athlete_uuid,
                   club_uuid: club3_uuid
                 })
               ),
             do:
               Athlete.set_club_memberships(athlete, %SetAthleteClubMemberships{
                 athlete_uuid: athlete_uuid,
                 club_uuids: [club1_uuid, club2_uuid]
               })

      assert events == [
               %AthleteJoinedClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club1_uuid,
                 firstname: "Ben",
                 lastname: "Smith",
                 gender: "M"
               },
               %AthleteJoinedClub{
                 athlete_uuid: athlete_uuid,
                 club_uuid: club2_uuid,
                 firstname: "Ben",
                 lastname: "Smith",
                 gender: "M"
               },
               %AthleteLeftClub{athlete_uuid: athlete_uuid, club_uuid: club3_uuid}
             ]
    end
  end

  describe "starred Strava segments" do
    @tag :unit
    test "import starred segments" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             do:
               Athlete.import_starred_segments(athlete, [
                 struct(Strava.DetailedSegment, build(:strava_segment))
               ])

      assert events == [
               struct(
                 AthleteStarredStravaSegment,
                 build(:strava_segment, %{
                   athlete_uuid: athlete_uuid,
                   strava_segment_id: 8_622_812,
                   distance_in_metres: 908.2
                 })
               )
             ]
    end

    @tag :unit
    test "import starred segments when unchanged" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             athlete <-
               evolve(
                 athlete,
                 Athlete.import_starred_segments(athlete, [
                   struct(Strava.DetailedSegment, build(:strava_segment))
                 ])
               ),
             do:
               Athlete.import_starred_segments(athlete, [
                 struct(Strava.DetailedSegment, build(:strava_segment))
               ])

      assert events == []
    end

    @tag :unit
    test "import starred segments when segment unstarred" do
      athlete_uuid = UUID.uuid4()

      events =
        with athlete <- evolve(%Athlete{}, import_example_athlete(athlete_uuid)),
             athlete <-
               evolve(
                 athlete,
                 Athlete.import_starred_segments(athlete, [
                   struct(Strava.DetailedSegment, build(:strava_segment))
                 ])
               ),
             do: Athlete.import_starred_segments(athlete, [])

      assert events == [
               %AthleteUnstarredStravaSegment{
                 athlete_uuid: athlete_uuid,
                 strava_segment_id: 8_622_812
               }
             ]
    end
  end

  defp import_example_athlete(athlete_uuid, params \\ %{}) do
    Athlete.import_athlete(
      %Athlete{},
      struct(
        ImportAthlete,
        build(:athlete, Map.merge(%{athlete_uuid: athlete_uuid, gender: "M"}, params))
      )
    )
  end

  defp evolve(%Athlete{} = athlete, events) do
    Enum.reduce(List.wrap(events), athlete, &Athlete.apply(&2, &1))
  end
end
