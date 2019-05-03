defmodule SegmentChallengeWeb.ChallengeLeaderboardController do
  use SegmentChallengeWeb, :controller

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
  plug(:set_active_challenge_section, :leaderboards)

  def show(%{assigns: %{challenge: challenge}} = conn, params) do
    %ChallengeProjection{challenge_uuid: challenge_uuid} = challenge

    stages = StagesInChallengeQuery.new(challenge_uuid) |> Repo.all()

    case leaderboard_to_show(challenge) do
      :challenge -> show_challenge_leaderboards(conn, params, challenge_uuid, stages)
      :stage -> show_stage_leaderboards(conn, params, stages)
    end
  end

  defp leaderboard_to_show(%ChallengeProjection{} = challenge) do
    case ChallengeProjection.hide_challenge_stages?(challenge) do
      true -> :stage
      false -> :challenge
    end
  end

  defp show_challenge_leaderboards(conn, params, challenge_uuid, stages) do
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
      stages: stages,
      stage: Enum.find(stages, fn stage -> stage.status == "active" end),
      commands: []
    )
  end

  defp show_stage_leaderboards(conn, params, [stage | _stages] = stages) do
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
      commands: []
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
end
