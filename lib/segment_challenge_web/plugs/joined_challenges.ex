defmodule SegmentChallengeWeb.Plugs.JoinedChallenges do
  use Phoenix.Controller, namespace: SegmentChallengeWeb

  import Plug.Conn

  alias SegmentChallenge.Challenges.Queries.Challenges.CompetitorChallengesQuery
  alias SegmentChallenge.Repo

  def init(options), do: options

  def call(%Plug.Conn{assigns: assigns} = conn, _opts) do
    assign(conn, :joined_challenges, competitor_challenge_uuids(assigns))
  end

  defp competitor_challenge_uuids(%{current_athlete: nil}), do: MapSet.new()

  defp competitor_challenge_uuids(%{current_athlete: %{athlete_uuid: athlete_uuid}}) do
    athlete_uuid |> CompetitorChallengesQuery.new() |> Repo.all() |> MapSet.new()
  end
end
