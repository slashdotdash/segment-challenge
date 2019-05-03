defmodule SegmentChallenge.UseCases.Strava do
  alias SegmentChallenge.Strava.Gateway, as: StravaGateway

  def strava_stage_efforts(segment_id, start_date_local, end_date_local) do
    client = strava_client()

    StravaGateway.segment_efforts(client, segment_id, start_date_local, end_date_local)
  end

  def strava_stage_activities(start_date_utc, end_date_utc) do
    client = strava_client()

    StravaGateway.athlete_activities(client, start_date_utc, end_date_utc)
  end

  def strava_activity(activity_id) do
    client = strava_client()

    StravaGateway.get_activity(client, activity_id)
  end

  def starred_segments do
    client = strava_client()

    StravaGateway.starred_segments(client)
  end

  def strava_client do
    access_token = Application.get_env(:strava, :access_token)
    refresh_token = Application.get_env(:strava, :refresh_token)

    Strava.Client.new(access_token, refresh_token: refresh_token)
  end
end
