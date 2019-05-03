defmodule SegmentChallengeWeb.StageActivityController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Authorisation.Policies.StagePolicy
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Challenges.Queries.ActivityFeeds.{ActivityFeedForObjectQuery}
  alias SegmentChallenge.Repo

  plug(:set_active_section, :challenge)
  plug(:set_active_stage_section, :activity)

  def show(%{assigns: %{stage: stage, challenge: challenge}} = conn, params) do
    activities = paginate_feed_query(stage.stage_uuid, params)

    render(
      conn,
      "show.html",
      activities: activities,
      commands: commands(conn, stage, challenge)
    )
  end

  def paginate_feed_query(stage_uuid, params) do
    ActivityFeedForObjectQuery.new("stage", stage_uuid) |> Repo.next_page(params)
  end

  defp commands(%{assigns: %{current_athlete: nil}}, _stage, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, stage, challenge) do
    StagePolicy.commands(struct(User, current_athlete), stage, challenge)
  end
end
