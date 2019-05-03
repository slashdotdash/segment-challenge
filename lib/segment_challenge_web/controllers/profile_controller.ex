defmodule SegmentChallengeWeb.ProfileController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Challenges.Queries.Profiles.ProfileQuery
  alias SegmentChallenge.Repo

  @blank_gif <<71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 128, 0, 0, 0, 0, 0, 255, 255, 255, 33, 249, 4, 1, 0, 0, 0, 0, 44, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 1, 68, 0, 59>>

  def show(conn, %{"source" => source, "source_uuid" => source_uuid}) do
    case ProfileQuery.new(source, source_uuid) |> Repo.one do
      nil ->
        send_blank_gif(conn)

      profile ->
        case profile.profile do
          "http" <> _url = image ->
            conn
            |> put_status(:moved_permanently)
            |> redirect(external: image)

          _ ->
            send_blank_gif(conn)
        end
    end
  end

  defp send_blank_gif(conn) do
    conn
    |> put_resp_content_type("image/gif")
    |> send_resp(200, @blank_gif)
  end
end
