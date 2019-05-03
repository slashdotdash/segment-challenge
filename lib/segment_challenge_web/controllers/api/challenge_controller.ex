defmodule SegmentChallengeWeb.API.ChallengeController do
  use SegmentChallengeWeb, :controller

  require Logger

  import Canada.Can, only: [can?: 3]

  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.{Repo, Router}
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallengeWeb.CreateChallengeBuilder
  alias SegmentChallengeWeb.CommandResponder
  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(EnsureAuthenticated)

  @doc """
  Create a new challenge.
  """
  def create(conn, params) do
    command = CreateChallengeBuilder.build(conn, params)
    user = current_user(conn)

    if can?(user, :dispatch, command) do
      case Router.dispatch(command, consistency: :strong) do
        :ok ->
          redirect_to_challenge(conn, command)

        {:error, :consistency_timeout} = result ->
          Logger.error(fn ->
            "Dispatch command consistency timeout: #{inspect(command)}, user: #{inspect(user)}"
          end)

          send_command_response(conn, result)

        result ->
          send_command_response(conn, result)
      end
    else
      Logger.warn(fn ->
        "Unauthorised command dispatch attempted by #{inspect(user)}: #{inspect(command)}"
      end)

      send_resp(conn, 403, "{}")
    end
  end

  defp current_user(conn) do
    case current_athlete_uuid(conn) do
      nil -> nil
      athlete_uuid -> %User{athlete_uuid: athlete_uuid}
    end
  end

  defp redirect_to_challenge(conn, %{challenge_uuid: challenge_uuid}) do
    %ChallengeProjection{url_slug: url_slug} = Repo.get!(ChallengeProjection, challenge_uuid)

    send_redirect(conn, challenge_path(conn, :show, url_slug))
  end

  defp send_redirect(conn, to) do
    send_resp(conn, 201, "{\"redirect_to\": \"#{to}\"}")
  end

  defp send_command_response(conn, result) do
    CommandResponder.respond(conn, result)
  end
end
