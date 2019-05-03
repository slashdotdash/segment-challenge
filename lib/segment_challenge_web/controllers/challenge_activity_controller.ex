defmodule SegmentChallengeWeb.ChallengeActivityController do
  use SegmentChallengeWeb, :controller

  require Ecto.Query
  require Logger

  alias SegmentChallenge.Repo
  alias SegmentChallenge.Challenges.Queries.ActivityFeeds.ChallengeActivityFeedQuery
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Projections.ChallengeProjection

  plug(:set_active_section, :challenge)
  plug(:set_active_challenge_section, :activity)

  def show(%{assigns: %{challenge: challenge}} = conn, params) do
    %ChallengeProjection{challenge_uuid: challenge_uuid} = challenge

    stage_uuids =
      challenge_uuid
      |> StagesInChallengeQuery.new()
      |> Ecto.Query.select([s], s.stage_uuid)
      |> Repo.all()

    activities = paginate_activity_feed(challenge_uuid, stage_uuids, params)

    render(
      conn,
      "show.html",
      activities: activities,
      commands: []
    )
  end

  def paginate_activity_feed(challenge_uuid, stage_uuids, params) do
    ChallengeActivityFeedQuery.new(challenge_uuid, stage_uuids) |> Repo.next_page(params)
  end
end
