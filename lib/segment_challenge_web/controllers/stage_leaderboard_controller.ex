defmodule SegmentChallengeWeb.StageLeaderboardController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Authorisation.Policies.StagePolicy
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Challenges.Queries.Leaderboards.StageLeaderboardsForStageQuery
  alias SegmentChallenge.Challenges.Queries.Leaderboards.StageLeaderboardEntriesQuery
  alias SegmentChallenge.Challenges.Queries.Stages.StageEffortsQuery
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Repo

  plug(:set_active_section, :challenge)
  plug(:set_active_stage_section, :leaderboards)

  def show(%{assigns: %{stage: stage, challenge: challenge}} = conn, params) do
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
      leaderboards: leaderboards,
      selected_leaderboard: selected_leaderboard,
      leaderboard_entries: leaderboard_entries,
      selected_athlete: selected_athlete,
      stage_efforts: stage_efforts,
      commands: commands(conn, stage, challenge)
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

  defp commands(%{assigns: %{current_athlete: nil}}, _stage, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, stage, challenge) do
    StagePolicy.commands(struct(User, current_athlete), stage, challenge)
  end
end
