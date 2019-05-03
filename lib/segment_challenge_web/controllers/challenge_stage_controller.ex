defmodule SegmentChallengeWeb.ChallengeStageController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Authorisation.Policies.{ChallengePolicy, StagePolicy}
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery

  plug(:set_active_section, :challenge)
  plug(:set_active_challenge_section, :stages)

  def show(%{assigns: %{challenge: challenge}} = conn, _params) do
    stages = StagesInChallengeQuery.new(challenge.challenge_uuid) |> Repo.all()

    stage_commands =
      Enum.reduce(stages, %{}, fn stage, commands ->
        Map.put(commands, stage.stage_number, commands(conn, stage, challenge))
      end)

    render(
      conn,
      "show.html",
      stages: stages,
      commands: commands(conn, challenge),
      stage_commands: stage_commands
    )
  end

  # Get all authorised commands for the challenge
  defp commands(%{assigns: %{current_athlete: nil}}, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, challenge) do
    ChallengePolicy.commands(struct(User, current_athlete), challenge)
  end

  defp commands(%{assigns: %{current_athlete: nil}}, _stage, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, stage, challenge) do
    StagePolicy.commands(struct(User, current_athlete), stage, challenge)
  end
end
