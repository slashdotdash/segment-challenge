defmodule SegmentChallengeWeb.Plugs.EnsureAuthenticated do
  use SegmentChallengeWeb, :controller

  import Plug.Conn

  def init(options), do: options

  def call(%Plug.Conn{} = conn, _opts) do
    %Plug.Conn{request_path: request_path} = conn

    case current_athlete_uuid(conn) do
      nil ->
        if is_json_request?(conn) do
          conn
          |> delete_session(:redirect_to)
          |> send_resp(403, "")
          |> halt()
        else
          conn
          |> put_session(:redirect_to, request_path)
          |> redirect(to: auth_path(conn, :index))
          |> halt()
        end

      _athlete_uuid ->
        conn
    end
  end

  defp is_json_request?(%Plug.Conn{} = conn) do
    %Plug.Conn{req_headers: req_headers} = conn

    Enum.member?(req_headers, {"accept", "application/json"})
  end
end
