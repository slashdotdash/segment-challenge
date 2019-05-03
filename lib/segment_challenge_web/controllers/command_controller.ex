defmodule SegmentChallengeWeb.CommandController do
  use SegmentChallengeWeb, :controller

  require Logger

  import Canada.Can, only: [can?: 3]

  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Router
  alias SegmentChallengeWeb.CommandBuilder
  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(EnsureAuthenticated)

  @doc """
  Dispatch the command defined in the `params`
  """
  def dispatch(conn, %{"command" => command, "redirect_to" => redirect_to} = params) do
    command = CommandBuilder.build(command, conn, Map.drop(params, ["command", "redirect_to"]))
    user = current_user(conn)

    if can?(user, :dispatch, command) do
      case Router.dispatch(command, consistency: :strong) do
        :ok ->
          conn
          |> after_dispatch(command)
          |> redirect(to: redirect_to)

        {:error, :consistency_timeout} ->
          Logger.error(fn ->
            "Dispatch command consistency timeout: #{inspect(command)}, user: #{inspect(user)}"
          end)

          conn
          |> after_dispatch(command)
          |> redirect(to: redirect_to)

        {:error, {:validation_failure, errors}} ->
          render_validation_failure(conn, errors, redirect_to)

        reply ->
          Logger.error(fn ->
            "Failed to dispatch command: #{inspect(command)}, user: #{inspect(user)}, due to: #{
              inspect(reply)
            }"
          end)

          render_bad_request(conn)
      end
    else
      Logger.warn(fn ->
        "Command authorization failed, command: #{inspect(command)}, user: #{inspect(user)}"
      end)

      render_bad_request(conn)
    end
  end

  alias SegmentChallenge.Stages.Stage.Commands.ConfigureAthleteGenderInStage

  defp after_dispatch(
         %{assigns: %{current_athlete: current_athlete}} = conn,
         %ConfigureAthleteGenderInStage{} = command
       ) do
    %ConfigureAthleteGenderInStage{gender: gender} = command

    current_athlete = Map.put(current_athlete, :gender, gender)

    put_session(conn, :current_athlete, current_athlete)
  end

  defp after_dispatch(conn, _command), do: conn

  defp render_validation_failure(conn, errors, redirect_to) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(:dispatch, errors: errors, redirect_to: redirect_to)
    |> halt()
  end

  defp render_bad_request(conn) do
    conn
    |> put_status(:bad_request)
    |> put_view(SegmentChallengeWeb.ErrorView)
    |> render("400.html")
    |> halt()
  end

  defp current_user(conn) do
    case current_athlete_uuid(conn) do
      nil -> nil
      athlete_uuid -> %User{athlete_uuid: athlete_uuid}
    end
  end
end
