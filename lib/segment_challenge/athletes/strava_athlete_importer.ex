defmodule SegmentChallenge.Athletes.StravaAthleteImporter do
  @moduledoc """
  Import an athlete, including their clubs and favourite segments, from Strava.
  """

  use Timex

  require Logger

  alias SegmentChallenge.Commands.ImportAthlete
  alias SegmentChallenge.Commands.ImportClub
  alias SegmentChallenge.Commands.SetAthleteClubMemberships
  alias SegmentChallenge.Clubs.Club
  alias SegmentChallenge.Projections.Clubs.ClubProjection
  alias SegmentChallenge.{Repo, Router}
  alias SegmentChallenge.Strava.Gateway, as: StravaGateway
  alias SegmentChallenge.Strava.StravaAccess

  def execute(athlete_uuid, access_token, refresh_token, %Strava.DetailedAthlete{} = athlete) do
    client = StravaGateway.build_client(athlete_uuid, access_token, refresh_token)

    with :ok <- import_athlete(athlete_uuid, athlete),
         :ok <- StravaAccess.assign_access_token(athlete_uuid, access_token, refresh_token),
         clubs <- StravaGateway.athlete_clubs(client),
         :ok <- set_athlete_club_memberships(athlete_uuid, clubs),
         :ok <- do_import_clubs(client, clubs) do
      :ok
    else
      {:error, error} = reply ->
        Logger.error(fn ->
          "Failed to import Strava athlete #{athlete_uuid} due to: " <> inspect(error)
        end)

        reply
    end
  end

  def import_clubs(athlete_uuid, access_token, refresh_token) do
    client = StravaGateway.build_client(athlete_uuid, access_token, refresh_token)

    with clubs <- StravaGateway.athlete_clubs(client),
         :ok <- set_athlete_club_memberships(athlete_uuid, clubs),
         :ok <- do_import_clubs(client, clubs) do
      {:ok, List.wrap(clubs)}
    else
      {:error, error} = reply ->
        Logger.error(fn ->
          "Failed to import clubs for Strava athlete #{athlete_uuid} due to: " <> inspect(error)
        end)

        reply
    end
  end

  defp import_athlete(athlete_uuid, %Strava.DetailedAthlete{} = athlete) do
    %Strava.DetailedAthlete{
      id: id,
      firstname: firstname,
      lastname: lastname,
      profile: profile,
      city: city,
      state: state,
      country: country,
      sex: sex,
      measurement_preference: measurement_preference,
      email: email,
      ftp: ftp,
      weight: weight
    } = athlete

    command = %ImportAthlete{
      athlete_uuid: athlete_uuid,
      strava_id: id,
      firstname: firstname,
      lastname: lastname,
      profile: profile,
      city: city,
      state: state,
      country: country,
      gender: sex,
      measurement_preference: measurement_preference,
      email: email,
      ftp: ftp,
      weight: weight
    }

    Router.dispatch(command)
  end

  defp set_athlete_club_memberships(_athlete_uuid, nil), do: :ok

  defp set_athlete_club_memberships(athlete_uuid, strava_clubs) do
    club_uuids =
      Enum.map(strava_clubs, fn %Strava.SummaryClub{id: id} ->
        Club.identity(id)
      end)

    Router.dispatch(%SetAthleteClubMemberships{
      athlete_uuid: athlete_uuid,
      club_uuids: club_uuids
    })
  end

  defp do_import_clubs(_client, nil), do: :ok

  defp do_import_clubs(client, clubs) do
    Enum.each(clubs, &import_club(client, &1))
  end

  defp import_club(client, %Strava.SummaryClub{} = club) do
    %Strava.SummaryClub{id: strava_id} = club

    club_uuid = Club.identity(strava_id)

    if import_club?(club, club_uuid) do
      {:ok, %Strava.DetailedClub{} = strava_club} = Strava.Clubs.get_club_by_id(client, strava_id)

      %Strava.DetailedClub{
        id: strava_id,
        name: name,
        sport_type: sport_type,
        city: city,
        state: state,
        country: country,
        profile_medium: profile,
        private: private
      } = strava_club

      command = %ImportClub{
        club_uuid: club_uuid,
        strava_id: strava_id,
        name: name,
        sport_type: sport_type,
        city: city,
        state: state,
        country: country,
        profile: profile,
        private: private
      }

      Router.dispatch(command)
    end
  end

  # Only import new clubs, or when the club profile image has changed
  defp import_club?(%Strava.SummaryClub{} = club, club_uuid) do
    %Strava.SummaryClub{profile_medium: profile} = club

    case Repo.get(ClubProjection, club_uuid) do
      nil -> true
      club -> club.profile != profile
    end
  end
end
