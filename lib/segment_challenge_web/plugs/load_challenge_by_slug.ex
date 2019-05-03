defmodule SegmentChallengeWeb.Plugs.LoadChallengeBySlug do
  use Phoenix.Controller, namespace: SegmentChallengeWeb

  import Plug.Conn

  alias SegmentChallenge.Projections.Challenges.ChallengeProjection
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengeBySlugQuery
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Repo

  def init(options), do: options

  def call(%Plug.Conn{params: %{"slug" => slug}} = conn, _opts) do
    with {:ok, challenge} <- get_challenge_by_slug(slug),
         {:ok, challenge} <- is_visible?(conn, challenge) do
      assign(conn, :challenge, challenge)
    else
      _ -> not_found(conn)
    end
  end

  defp get_challenge_by_slug(slug) do
    slug
    |> ChallengeBySlugQuery.new()
    |> Repo.one()
    |> case do
      nil -> nil
      challenge -> {:ok, challenge}
    end
  end

  defp is_visible?(conn, %ChallengeProjection{status: status} = challenge) do
    case status do
      "pending" -> created_by_current_athlete(conn, challenge)
      _ -> {:ok, challenge}
    end
  end

  defp created_by_current_athlete(
         conn,
         %ChallengeProjection{created_by_athlete_uuid: created_by_athlete_uuid} = stage
       ) do
    case current_athlete_uuid(conn) do
      ^created_by_athlete_uuid -> {:ok, stage}
      _ -> nil
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(SegmentChallengeWeb.ErrorView)
    |> render("404.html")
    |> halt
  end

  defp current_athlete_uuid(%{assigns: %{current_athlete: %{athlete_uuid: athlete_uuid}}}),
    do: athlete_uuid

  defp current_athlete_uuid(_conn), do: nil
end
