defmodule SegmentChallengeWeb.API.CommandController do
  use SegmentChallengeWeb, :controller

  require Logger

  import Canada.Can, only: [can?: 3]

  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Router
  alias SegmentChallengeWeb.CommandBuilder
  alias SegmentChallengeWeb.CommandResponder
  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(EnsureAuthenticated)

  @doc """
  Dispatch the command defined in the `params`
  """
  def dispatch(conn, %{"command" => command} = params) do
    command = CommandBuilder.build(command, conn, Map.delete(params, "command"))
    user = current_user(conn)

    if can?(user, :dispatch, command) do
      case Router.dispatch(command, consistency: :strong) do
        {:error, :consistency_timeout} = result ->
          Logger.error(fn ->
            "Dispatch command consistency timeout: #{inspect(command)}, user: #{inspect(user)}"
          end)

          CommandResponder.respond(conn, result)

        result ->
          CommandResponder.respond(conn, result)
      end
    else
      Logger.warn(fn ->
        "Unauthorised command dispatch attempted by #{inspect(user)}: #{inspect(command)}"
      end)

      send_resp(conn, 403, "{}")
    end
  end

  @doc """
  Attempted to dispatch missing command
  """
  def dispatch(conn, _params), do: send_resp(conn, 400, "{}")

  defp current_user(conn) do
    case current_athlete_uuid(conn) do
      nil -> nil
      athlete_uuid -> %User{athlete_uuid: athlete_uuid}
    end
  end
end
