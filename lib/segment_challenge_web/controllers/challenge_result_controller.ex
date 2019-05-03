defmodule SegmentChallengeWeb.ChallengeResultController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Authorisation.Policies.ChallengePolicy
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Challenges.Queries.Leaderboards.ChallengeLeaderboardQuery
  alias SegmentChallenge.Challenges.Queries.Leaderboards.ChallengeLeaderboardEntriesQuery
  alias SegmentChallenge.Challenges.Queries.Leaderboards.StageLeaderboardsForStageQuery
  alias SegmentChallenge.Challenges.Queries.Leaderboards.StageLeaderboardEntriesQuery
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Challenges.Queries.Stages.StageEffortsQuery
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Repo

  plug(:set_active_section, :challenge)
  plug(:set_active_challenge_section, :results)

  def show(%{assigns: %{challenge: challenge}} = conn, params) do
    %ChallengeProjection{challenge_uuid: challenge_uuid} = challenge

    stages = StagesInChallengeQuery.new(challenge_uuid) |> Repo.all()

    case leaderboard_to_show(challenge) do
      :challenge -> show_challenge_leaderboards(conn, params, challenge, stages)
      :stage -> show_stage_leaderboards(conn, params, challenge, stages)
    end
  end

  @doc """
  Publish challenge results.
  """
  def publish(%{assigns: %{challenge: challenge}} = conn, _params) do
    case command(:publish_challenge_results, conn, challenge) do
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
          redirect_to: challenge_url(conn, :show, challenge.url_slug)
        )
    end
  end

  defp leaderboard_to_show(%ChallengeProjection{} = challenge) do
    case ChallengeProjection.hide_challenge_stages?(challenge) do
      true -> :stage
      false -> :challenge
    end
  end

  defp show_challenge_leaderboards(conn, params, challenge, stages) do
    %ChallengeProjection{challenge_uuid: challenge_uuid} = challenge

    leaderboards = ChallengeLeaderboardQuery.new(challenge_uuid) |> Repo.all()
    selected_leaderboard = get_selected_leaderboard(params, leaderboards)

    leaderboard_entries =
      case selected_leaderboard do
        nil ->
          []

        leaderboard ->
          ChallengeLeaderboardEntriesQuery.new(leaderboard.challenge_leaderboard_uuid)
          |> Repo.all()
      end

    render(
      conn,
      "show.html",
      template: "challenge_leaderboards.html",
      leaderboards: leaderboards,
      selected_leaderboard: selected_leaderboard,
      leaderboard_entries: leaderboard_entries,
      selected_athlete: nil,
      stage_efforts: nil,
      stages: stages,
      stage: Enum.find(stages, fn stage -> stage.status == "active" end),
      commands: commands(conn, challenge)
    )
  end

  defp show_stage_leaderboards(conn, params, challenge, [stage | _stages] = stages) do
    %StageProjection{stage_uuid: stage_uuid} = stage

    leaderboards = StageLeaderboardsForStageQuery.new(stage_uuid) |> Repo.all()
    selected_leaderboard = get_selected_leaderboard(params, leaderboards)
    selected_athlete = get_selected_athlete(params)

    leaderboard_entries =
      case selected_leaderboard do
        nil ->
          []

        leaderboard ->
          StageLeaderboardEntriesQuery.new(leaderboard.stage_leaderboard_uuid) |> Repo.all()
      end

    stage_efforts =
      case selected_athlete do
        nil ->
          nil

        athlete_uuid ->
          StageEffortsQuery.new(athlete_uuid: athlete_uuid, stage_uuid: stage_uuid) |> Repo.all()
      end

    render(
      conn,
      "show.html",
      template: "stage_leaderboards.html",
      stage: stage,
      stages: stages,
      leaderboards: leaderboards,
      selected_leaderboard: selected_leaderboard,
      leaderboard_entries: leaderboard_entries,
      selected_athlete: selected_athlete,
      stage_efforts: stage_efforts,
      commands: commands(conn, challenge)
    )
  end

  defp get_selected_leaderboard(_params, []), do: nil

  defp get_selected_leaderboard(%{"leaderboard" => name, "gender" => gender}, leaderboards) do
    Enum.find(leaderboards, hd(leaderboards), fn leaderboard ->
      leaderboard.name == name && leaderboard.gender == gender
    end)
  end

  defp get_selected_leaderboard(_params, leaderboards), do: hd(leaderboards)

  defp get_selected_athlete(%{"athlete_uuid" => athlete_uuid}), do: athlete_uuid
  defp get_selected_athlete(_params), do: nil

  defp command(_name, %{assigns: %{current_athlete: nil}}, _challenge), do: nil

  defp command(name, %{assigns: %{current_athlete: current_athlete}}, challenge) do
    ChallengePolicy.command(name, struct(User, current_athlete), challenge)
  end

  defp commands(%{assigns: %{current_athlete: nil}}, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, challenge) do
    ChallengePolicy.commands(struct(User, current_athlete), challenge)
  end
end
