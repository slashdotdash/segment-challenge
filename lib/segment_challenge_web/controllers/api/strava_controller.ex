defmodule SegmentChallengeWeb.API.StravaController do
  use SegmentChallengeWeb, :controller

  require Logger

  def subscribe(conn, %{"hub.challenge" => hub_challenge}) do
    send_json(conn, """
    {"hub.challenge": "#{hub_challenge}"}
    """)
  end

  def subscribe(conn, params) do
    Logger.error(fn ->
      {"Invalid Strava webhook subscription response", [params: inspect(params)]}
    end)

    send_resp(conn, 500, "")
  end

  def webhook(conn, %{"object_type" => "activity"} = params) do
    %{
      "aspect_type" => aspect_type,
      "object_id" => strava_activity_id,
      "owner_id" => strava_athlete_id
    } = params

    Logger.info(fn -> "Strava webhook: " <> inspect(params) end)

    job =
      case aspect_type do
        "create" -> SegmentChallenge.Jobs.ImportStravaActivity
        "delete" -> SegmentChallenge.Jobs.RemoveStravaActivity
        "update" -> SegmentChallenge.Jobs.UpdateStravaActivity
      end

    Rihanna.enqueue(job,
      strava_activity_id: strava_activity_id,
      strava_athlete_id: strava_athlete_id
    )

    send_resp(conn, 200, "")
  end

  def webhook(conn, %{"aspect_type" => "update", "object_type" => "athlete"} = params) do
    %{"updates" => athlete_updates, "owner_id" => strava_athlete_id} = params

    Logger.info(fn -> "Strava webhook: " <> inspect(params) end)

    if Map.get(athlete_updates, "authorized") in ["false", false] do
      Rihanna.enqueue(SegmentChallenge.Jobs.RevokeAthleteAccess,
        strava_athlete_id: strava_athlete_id
      )
    end

    send_resp(conn, 200, "")
  end

  def webhook(conn, params) do
    Logger.info(fn -> "Strava webhook: " <> inspect(params) end)

    send_resp(conn, 200, "")
  end

  defp send_json(conn, json) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end
end
