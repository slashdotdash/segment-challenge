defmodule SegmentChallengeWeb.Plugs.AssignCurrentUser do
  import Plug.Conn

  def init(options), do: options

  @doc """
  Fetch the current user from the session and add it to `conn.assigns`.
  To allow access to the current athlete in any view with `@current_athlete`.
  """
  def call(%Plug.Conn{} = conn, _opts) do
    assign(conn, :current_athlete, get_session(conn, :current_athlete))
  end
end
