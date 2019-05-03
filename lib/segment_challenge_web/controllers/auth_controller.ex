defmodule SegmentChallengeWeb.AuthController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Athletes.Athlete
  alias SegmentChallenge.Athletes.StravaAthleteImporter
  alias SegmentChallenge.Strava.Gateway, as: StravaGateway

  def index(conn, _params) do
    scope = "read,profile:read_all,activity:read,activity:read_all"
    url = Strava.Auth.authorize_url!(approval_prompt: "auto", scope: scope)

    redirect(conn, external: url)
  end

  def delete(conn, _params) do
    conn
    |> logout()
    |> redirect(to: "/")
  end

  @doc """
  This action is reached via `/auth/callback` and is the the callback URL that
  Strava will redirect the user back to with a `code` that will be used to
  request an access token. The access token will then be used to access
  protected resources on behalf of the user.
  """
  def callback(conn, %{"code" => code}) do
    %OAuth2.Client{
      token: %OAuth2.AccessToken{access_token: access_token, refresh_token: refresh_token} = token
    } = Strava.Auth.get_token!(code: code)

    athlete = Strava.Auth.get_athlete!(token)
    athlete_uuid = Athlete.identity(athlete.id)
    client = StravaGateway.build_client(athlete_uuid, access_token, refresh_token)

    with {:ok, %Strava.DetailedAthlete{} = athlete} <-
           Strava.Athletes.get_logged_in_athlete(client) do
      import_athlete(athlete_uuid, access_token, refresh_token, athlete)

      conn
      |> track_current_athlete(athlete_uuid, athlete)
      |> redirect_to()
    else
      _ -> redirect_to(conn)
    end
  end

  @doc """
  Action reached when a user denies authorisation of the Segment Challenge
  Strava app. Redirect user to homepage.
  """
  def callback(conn, _params) do
    redirect(conn, to: page_path(conn, :index))
  end

  defp logout(conn) do
    conn
    |> put_flash(:info, "You have been logged out.")
    |> configure_session(drop: true)
  end

  # Redirect to session redirect target, or athlete's dashboard.
  defp redirect_to(conn) do
    case get_session(conn, :redirect_to) do
      nil -> redirect(conn, to: dashboard_path(conn, :index))
      path -> redirect(conn, to: path)
    end
  end

  # Import athlete in a separate, unlinked, process
  defp import_athlete(athlete_uuid, access_token, refresh_token, athlete) do
    Task.start(fn ->
      try do
        :ok = StravaAthleteImporter.execute(athlete_uuid, access_token, refresh_token, athlete)
      rescue
        exception ->
          Rollbax.report(:error, exception, System.stacktrace())
      end
    end)
  end

  defp track_current_athlete(conn, athlete_uuid, %Strava.DetailedAthlete{} = athlete) do
    %Strava.DetailedAthlete{
      id: strava_id,
      firstname: firstname,
      lastname: lastname,
      sex: gender,
      measurement_preference: measurement_preference,
      profile: profile,
      city: city,
      state: state,
      country: country
    } = athlete

    put_session(conn, :current_athlete, %{
      athlete_uuid: athlete_uuid,
      strava_id: strava_id,
      firstname: firstname,
      lastname: lastname,
      name: "#{firstname} #{lastname}",
      gender: gender,
      measurement_preference: measurement_preference,
      profile: profile,
      city: city,
      state: state,
      country: country
    })
  end
end
