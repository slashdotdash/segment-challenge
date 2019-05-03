defmodule SegmentChallengeWeb.Router do
  use SegmentChallengeWeb, :router
  use Plug.ErrorHandler

  alias SegmentChallengeWeb.Plugs

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:configure_scripts)
    plug(Plugs.AssignCurrentUser)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(Plugs.AssignCurrentUser)
  end

  pipeline :challenge do
    plug(Plugs.LoadChallengeBySlug)
    plug(Plugs.JoinedChallenges)
  end

  pipeline :stage do
    plug(Plugs.LoadStageBySlug)
  end

  scope "/", SegmentChallengeWeb do
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/challenges", ChallengeController, :index)
    get("/challenges/clubs", ChallengeController, :clubs)
    get("/challenges/competing", ChallengeController, :competing)
    get("/challenges/hosted", ChallengeController, :hosted)
    get("/challenges/past", ChallengeController, :past)
    get("/dashboard", DashboardController, :index)
    get("/host", HostChallengeController, :index)
    get("/host/:challenge_type", HostChallengeController, :new)
    get("/profiles/:source/:source_uuid", ProfileController, :show)
    get("/r/challenge/:challenge_uuid", RedirectController, :challenge)
    get("/r/stage/:stage_uuid", RedirectController, :stage)
    get("/settings/email", EmailNotificationController, :index)
    get("/trophy-case", TrophyController, :index)
    post("/commands", CommandController, :dispatch)
  end

  scope "/challenges/:slug", SegmentChallengeWeb do
    pipe_through(:browser)
    pipe_through(:challenge)

    get("/", ChallengeController, :show)
    get("/activity", ChallengeActivityController, :show)
    get("/approve", ChallengeController, :approve)
    get("/edit", ChallengeController, :edit)
    get("/host", ChallengeController, :host)
    get("/join", ChallengeController, :join)
    get("/leaderboards", ChallengeLeaderboardController, :show)
    get("/leaderboards/:athlete_uuid", ChallengeLeaderboardController, :show)
    get("/publish", ChallengeResultController, :publish)
    get("/results", ChallengeResultController, :show)
    get("/results/:athlete_uuid", ChallengeResultController, :show)
    get("/stages", ChallengeStageController, :show)
    get("/stages/new", StageController, :new)
  end

  scope "/challenges/:challenge_slug/:stage_slug", SegmentChallengeWeb do
    pipe_through(:browser)
    pipe_through(:stage)

    get("/", StageController, :show)
    get("/activity", StageActivityController, :show)
    get("/edit", StageController, :edit)
    get("/leaderboards", StageLeaderboardController, :show)
    get("/leaderboards/:athlete_uuid", StageLeaderboardController, :show)
    get("/missing-attempt", StageController, :missing_attempt)
    get("/publish", StageResultController, :publish)
    get("/results", StageResultController, :show)
    get("/results/:athlete_uuid", StageResultController, :show)
  end

  scope "/auth", SegmentChallengeWeb do
    pipe_through(:browser)

    get("/", AuthController, :index)
    get("/callback", AuthController, :callback)
    delete("/logout", AuthController, :delete)
  end

  scope "/api", SegmentChallengeWeb, as: :api do
    pipe_through(:api)

    get("/athlete/clubs", API.AthleteController, :clubs)
    post("/athlete/clubs", API.AthleteController, :refresh_clubs)
    get("/athlete/segments/starred", API.AthleteController, :starred_segments)
    post("/challenges", API.ChallengeController, :create)
    post("/commands", API.CommandController, :dispatch)
    post("/stages", API.StageController, :create)
    get("/strava/webhook", API.StravaController, :subscribe)
    post("/strava/webhook", API.StravaController, :webhook)
  end

  if Mix.env() == :dev, do: forward("/sent_emails", Bamboo.SentEmailViewerPlug)

  def handle_errors(_conn, %{reason: %Phoenix.Router.NoRouteError{}}), do: :ok

  def handle_errors(conn, assigns) do
    %{kind: kind, reason: reason, stack: stacktrace} = assigns

    conn =
      conn
      |> Plug.Conn.fetch_cookies()
      |> Plug.Conn.fetch_query_params()

    params =
      case conn.params do
        %Plug.Conn.Unfetched{aspect: :params} -> "unfetched"
        other -> other
      end

    conn_data = %{
      "request" => %{
        "cookies" => conn.req_cookies,
        "url" => "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
        "user_ip" => List.to_string(:inet.ntoa(conn.remote_ip)),
        "headers" => Enum.into(conn.req_headers, %{}),
        "params" => params,
        "method" => conn.method
      }
    }

    Rollbax.report(kind, reason, stacktrace, %{}, conn_data)
  end

  defp configure_scripts(conn, _) do
    assign(conn, :scripts, [])
  end
end
