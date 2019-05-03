defmodule SegmentChallengeWeb.Plugs.IsClubMember do
  use Phoenix.Controller, namespace: SegmentChallengeWeb

  import Plug.Conn

  alias SegmentChallenge.Challenges.Queries.Clubs.ClubMemberQuery
  alias SegmentChallenge.Repo

  def init(options), do: options

  def call(%Plug.Conn{assigns: assigns} = conn, _opts) do
    assign(conn, :is_club_member, is_club_member?(assigns))
  end

  defp is_club_member?(%{current_athlete: nil}), do: false

  defp is_club_member?(%{challenge: challenge, current_athlete: current_athlete}) do
    case ClubMemberQuery.new(challenge.hosted_by_club_uuid, current_athlete.athlete_uuid)
         |> Repo.one() do
      nil -> false
      _ -> true
    end
  end
end
