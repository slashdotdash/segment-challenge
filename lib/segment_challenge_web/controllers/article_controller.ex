defmodule SegmentChallengeWeb.ArticleController do
  use SegmentChallengeWeb, :controller

  plug(:set_active_section, :article)

  def show(conn, %{"slug" => "how-to-improve-your-strava-segment-efforts"}) do
    render(conn, "improve-strava-segment.html")
  end

  def show(conn, _params), do: not_found(conn)

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(SegmentChallengeWeb.ErrorView)
    |> render("404.html")
  end
end
