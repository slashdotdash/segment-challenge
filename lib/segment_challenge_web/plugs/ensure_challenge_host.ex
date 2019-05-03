defmodule SegmentChallengeWeb.Plugs.EnsureChallengeHost do
  use SegmentChallengeWeb, :controller

  import Plug.Conn

  def init(options), do: options

  def call(
        %Plug.Conn{assigns: %{challenge: %{created_by_athlete_uuid: created_by_athlete_uuid}}} =
          conn,
        _opts
      ) do
    case current_athlete_uuid(conn) do
      ^created_by_athlete_uuid -> conn
      _ -> not_found(conn)
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(SegmentChallengeWeb.ErrorView)
    |> render("404.html")
    |> halt
  end
end
