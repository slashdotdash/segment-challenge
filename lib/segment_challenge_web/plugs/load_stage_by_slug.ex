defmodule SegmentChallengeWeb.Plugs.LoadStageBySlug do
  use Phoenix.Controller, namespace: SegmentChallengeWeb

  import Plug.Conn

  alias SegmentChallenge.Challenges.Queries.Stages.StageBySlugQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengeBySlugQuery
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Repo

  def init(options), do: options

  def call(%Plug.Conn{params: params} = conn, _opts) do
    %{
      "challenge_slug" => challenge_slug,
      "stage_slug" => stage_slug
    } = params

    with {:ok, challenge} <- get_challenge_by_slug(challenge_slug),
         {:ok, stage} <- get_stage_by_slug(challenge, stage_slug),
         {:ok, stage} <- ensure_stage_is_visible(conn, stage) do
      conn
      |> assign(:challenge, challenge)
      |> assign(:stage, stage)
    else
      _ -> not_found(conn)
    end
  end

  defp get_challenge_by_slug(slug) do
    case slug |> ChallengeBySlugQuery.new() |> Repo.one() do
      %ChallengeProjection{} = challenge -> {:ok, challenge}
      nil -> {:error, :challenge_not_found}
    end
  end

  defp get_stage_by_slug(%ChallengeProjection{} = challenge, slug) do
    %ChallengeProjection{challenge_uuid: challenge_uuid} = challenge

    case StageBySlugQuery.new(challenge_uuid, slug) |> Repo.one() do
      %StageProjection{} = stage -> {:ok, stage}
      nil -> {:error, :stage_not_found}
    end
  end

  defp ensure_stage_is_visible(_conn, %StageProjection{visible: true} = stage), do: {:ok, stage}

  defp ensure_stage_is_visible(conn, %StageProjection{visible: false} = stage) do
    if created_by_current_athlete?(conn, stage) do
      {:ok, stage}
    else
      {:error, :stage_not_visible}
    end
  end

  defp created_by_current_athlete?(conn, %StageProjection{} = stage) do
    %StageProjection{created_by_athlete_uuid: created_by_athlete_uuid} = stage

    case current_athlete_uuid(conn) do
      ^created_by_athlete_uuid -> true
      _ -> false
    end
  end

  defp current_athlete_uuid(%{assigns: %{current_athlete: %{athlete_uuid: athlete_uuid}}}),
    do: athlete_uuid

  defp current_athlete_uuid(_conn), do: nil

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(SegmentChallengeWeb.ErrorView)
    |> render("404.html")
    |> halt()
  end
end
