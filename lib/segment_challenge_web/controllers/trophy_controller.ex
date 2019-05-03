defmodule SegmentChallengeWeb.TrophyController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Repo
  alias SegmentChallenge.Athletes.Queries.AthleteBadgesQuery

  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(:set_active_section, :dashboard)
  plug(EnsureAuthenticated)
  plug(:set_active_dashboard_section, :trophy_case when action in [:index])

  @doc """
  Athlete's trophy cases containing achieved badges.
  """
  def index(conn, _params) do
    badges =
      conn
      |> current_athlete_uuid()
      |> AthleteBadgesQuery.new()
      |> Repo.all()

    render(conn, "index.html", badges: badges)
  end
end
