defmodule SegmentChallengeWeb.RedirectController do
  use SegmentChallengeWeb, :controller

  import Ecto.Query

  alias SegmentChallenge.Repo
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Projections.ChallengeProjection

  def challenge(conn, %{"challenge_uuid" => challenge_uuid}) do
    query =
      from(c in ChallengeProjection,
        where: c.challenge_uuid == ^challenge_uuid,
        select: c.url_slug
      )

    case Repo.one(query) do
      url_slug when is_binary(url_slug) ->
        redirect(conn, to: challenge_path(conn, :show, url_slug))

      nil ->
        not_found(conn)
    end
  end

  def stage(conn, %{"stage_uuid" => stage_uuid}) do
    query =
      from(s in StageProjection,
        join: c in ChallengeProjection,
        on: c.challenge_uuid == s.challenge_uuid,
        where: s.stage_uuid == ^stage_uuid,
        select: {c.url_slug, s.url_slug},
        limit: 1
      )

    case Repo.one(query) do
      {challenge_slug, stage_slug} when is_binary(challenge_slug) and is_binary(stage_slug) ->
        redirect(conn, to: stage_path(conn, :show, challenge_slug, stage_slug))

      nil ->
        not_found(conn)
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(SegmentChallengeWeb.ErrorView)
    |> render("404.html")
  end
end
