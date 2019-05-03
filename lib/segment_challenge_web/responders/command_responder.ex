defmodule SegmentChallengeWeb.CommandResponder do
  use Phoenix.Controller, namespace: SegmentChallengeWeb

  import Plug.Conn

  def respond(conn, :ok) do
    send_resp(conn, 201, "{}")
  end

  def respond(conn, {:error, :consistency_timeout}) do
    send_resp(conn, 201, "{}")
  end

  def respond(conn, {:error, {:validation_failure, errors}}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(SegmentChallengeWeb.API.CommandView)
    |> render(:dispatch, errors: errors)
  end

  def respond(conn, {:error, _error}) do
    send_resp(conn, 400, "{}")
  end
end
