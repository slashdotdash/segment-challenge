defmodule SegmentChallenge.Projections.Clubs do
  defmodule ClubProjection do
    use Ecto.Schema

    @primary_key {:club_uuid, :string, []}

    schema "clubs" do
      field(:strava_id, :integer)
      field(:name, :string)
      field(:sport_type, :string)
      field(:description, :string)
      field(:profile, :string)
      field(:city, :string)
      field(:state, :string)
      field(:country, :string)
      field(:website, :string)
      field(:last_imported_at, :naive_datetime)
      field(:private, :boolean, default: false)

      timestamps()
    end
  end

  defmodule AthleteClubMembershipProjection do
    use Ecto.Schema

    schema "athlete_club_memberships" do
      field(:athlete_uuid, :string)
      field(:club_uuid, :string)

      timestamps()
    end
  end

  alias SegmentChallenge.Projections.Clubs.{
    AthleteClubMembershipProjection,
    ClubProjection
  }

  defmodule Builder do
    use Commanded.Projections.Ecto, name: "ClubProjection"

    alias SegmentChallenge.Events.{
      ClubImported,
      ClubProfileChanged,
      AthleteJoinedClub,
      AthleteLeftClub
    }

    project %ClubImported{} = event, fn multi ->
      %ClubImported{
        club_uuid: club_uuid,
        strava_id: strava_id,
        name: name,
        description: description,
        sport_type: sport_type,
        city: city,
        state: state,
        country: country,
        profile: profile,
        website: website,
        private: private
      } = event

      Ecto.Multi.insert(
        multi,
        :club,
        %ClubProjection{
          club_uuid: club_uuid,
          strava_id: strava_id,
          name: name,
          description: description,
          sport_type: sport_type,
          city: city,
          state: state,
          country: country,
          profile: profile,
          website: website,
          private: private
        },
        on_conflict: [
          set: [
            strava_id: strava_id,
            name: name,
            description: description,
            sport_type: sport_type,
            city: city,
            state: state,
            country: country,
            profile: profile,
            website: website,
            private: private
          ]
        ],
        conflict_target: [:club_uuid]
      )
    end

    project %ClubProfileChanged{} = event, fn multi ->
      %ClubProfileChanged{club_uuid: club_uuid, profile: profile} = event

      Ecto.Multi.update_all(multi, :club, club_query(club_uuid), set: [profile: profile])
    end

    project %AthleteJoinedClub{} = event, fn multi ->
      %AthleteJoinedClub{athlete_uuid: athlete_uuid, club_uuid: club_uuid} = event

      Ecto.Multi.insert(
        multi,
        :athlete_club_membership,
        %AthleteClubMembershipProjection{
          athlete_uuid: athlete_uuid,
          club_uuid: club_uuid
        },
        on_conflict: :nothing,
        conflict_target: [:athlete_uuid, :club_uuid]
      )
    end

    project %AthleteLeftClub{} = event, fn multi ->
      %AthleteLeftClub{athlete_uuid: athlete_uuid, club_uuid: club_uuid} = event

      Ecto.Multi.delete_all(
        multi,
        :athlete_club_membership,
        athlete_club_membership_query(athlete_uuid, club_uuid)
      )
    end

    defp athlete_club_membership_query(athlete_uuid, club_uuid) do
      from(m in AthleteClubMembershipProjection,
        where: m.athlete_uuid == ^athlete_uuid and m.club_uuid == ^club_uuid
      )
    end

    defp club_query(club_uuid) do
      from(c in ClubProjection,
        where: c.club_uuid == ^club_uuid
      )
    end
  end
end
