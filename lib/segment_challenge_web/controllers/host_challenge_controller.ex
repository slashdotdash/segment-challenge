defmodule SegmentChallengeWeb.HostChallengeController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(:set_active_section, :host)
  plug(EnsureAuthenticated when action in [:new])

  @doc """
  Host a new challenge
  """
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @doc """
  Create a new challenge
  """
  def new(conn, %{"challenge_type" => challenge_type}) do
    conn
    |> include_script("/js/CreateChallenge.js")
    |> Plug.Conn.assign(:challenge_type, challenge_type)
    |> Plug.Conn.assign(:redirect_to, challenge_url(conn, :hosted))
    |> render("new.html")
  end
end
