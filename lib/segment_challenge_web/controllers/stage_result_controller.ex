defmodule SegmentChallengeWeb.StageResultController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Authorisation.Policies.StagePolicy
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Repo

  alias SegmentChallenge.Challenges.Queries.Leaderboards.{
    StageResultEntryQuery,
    StageResultQuery
  }

  plug(:set_active_section, :challenge)
  plug(:set_active_stage_section, :results)

  def show(%{assigns: %{stage: stage, challenge: challenge}} = conn, params) do
    stage_results = StageResultQuery.new(stage.stage_uuid) |> Repo.all()
    stage_result = get_selected_stage_result(params, stage_results)

    stage_result_entries =
      case stage_result do
        nil ->
          []

        stage_result ->
          StageResultEntryQuery.new(
            stage_result.challenge_leaderboard_uuid,
            stage_result.stage_uuid
          )
          |> Repo.all()
      end

    render(
      conn,
      "show.html",
      stage_results: stage_results,
      selected_stage_result: stage_result,
      stage_result_entries: stage_result_entries,
      commands: commands(conn, stage, challenge)
    )
  end

  @doc """
  Publish stage results.
  """
  def publish(%{assigns: %{stage: stage, challenge: challenge}} = conn, _params) do
    case command(:publish_stage_results, conn, stage, challenge) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(SegmentChallengeWeb.ErrorView)
        |> render("404.html")
        |> halt()

      command ->
        conn
        |> include_script("/js/MarkdownEditor.js")
        |> render(
          "publish.html",
          command: command,
          redirect_to: stage_url(conn, :show, challenge.url_slug, stage.url_slug)
        )
    end
  end

  defp get_selected_stage_result(_params, []), do: nil

  defp get_selected_stage_result(%{"leaderboard" => name, "gender" => gender}, stage_results) do
    Enum.find(stage_results, hd(stage_results), fn stage_result ->
      stage_result.name == name && stage_result.gender == gender
    end)
  end

  defp get_selected_stage_result(_params, stage_results), do: hd(stage_results)

  defp command(_name, %{assigns: %{current_athlete: nil}}, _stage, _challenge), do: nil

  defp command(name, %{assigns: %{current_athlete: current_athlete}}, stage, challenge) do
    StagePolicy.command(name, struct(User, current_athlete), stage, challenge)
  end

  defp commands(%{assigns: %{current_athlete: nil}}, _stage, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, stage, challenge) do
    StagePolicy.commands(struct(User, current_athlete), stage, challenge)
  end
end
