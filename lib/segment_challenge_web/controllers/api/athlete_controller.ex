defmodule SegmentChallengeWeb.API.AthleteController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Athletes.StravaAthleteImporter
  alias SegmentChallenge.Challenges.Queries.Clubs.ClubsByAthleteMembershipQuery
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Strava.Gateway, as: StravaGateway
  alias SegmentChallenge.Strava.StravaAccess
  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(EnsureAuthenticated)

  def clubs(conn, _params) do
    clubs = conn |> current_athlete_uuid() |> ClubsByAthleteMembershipQuery.new() |> Repo.all()

    render(conn, :clubs, clubs: clubs)
  end

  def refresh_clubs(conn, _params) do
    case strava_clubs(conn) do
      {:ok, clubs} ->
        render(conn, :clubs, clubs: clubs)

      {:error, _error} ->
        send_resp(conn, 400, "{}")
    end
  end

  def starred_segments(conn, _params) do
    case starred_segments(conn) do
      {:ok, starred_segments} ->
        render(conn, :starred_segments, starred_segments: starred_segments)

      {:error, _error} ->
        send_resp(conn, 400, "{}")
    end
  end

  defp starred_segments(conn) do
    with athlete_uuid when is_binary(athlete_uuid) <- current_athlete_uuid(conn),
         {:ok, access_token, refresh_token} <- StravaAccess.get_access_token(athlete_uuid),
         client <- StravaGateway.build_client(athlete_uuid, access_token, refresh_token) do
      starred_segments = StravaGateway.starred_segments(client)

      {:ok, starred_segments}
    else
      _ -> {:error, :not_found}
    end
  end

  defp strava_clubs(conn) do
    with athlete_uuid when is_binary(athlete_uuid) <- current_athlete_uuid(conn),
         {:ok, access_token, refresh_token} <- StravaAccess.get_access_token(athlete_uuid),
         {:ok, clubs} <-
           StravaAthleteImporter.import_clubs(athlete_uuid, access_token, refresh_token) do
      {:ok, clubs}
    else
      _ -> {:error, :failed}
    end
  end
end
