defmodule SegmentChallenge.Strava.Gateway do
  require Logger

  alias SegmentChallenge.Strava.StravaAccess
  alias SegmentChallenge.Strava.Cache

  def build_client(athlete_uuid, access_token, refresh_token) do
    Strava.Client.new(access_token,
      refresh_token: refresh_token,
      token_refreshed: &update_strava_access(athlete_uuid, &1)
    )
  end

  def segment_efforts(client, segment_id, start_date_local, end_date_local) do
    Strava.Paginator.stream(fn pagination ->
      params =
        pagination
        |> Keyword.put(:start_date_local, NaiveDateTime.to_iso8601(start_date_local))
        |> Keyword.put(:end_date_local, NaiveDateTime.to_iso8601(end_date_local))

      rate_limit_request(fn ->
        Strava.SegmentEfforts.get_efforts_by_segment_id(client, segment_id, params)
      end)
    end)
    |> Enum.to_list()
  end

  def athlete_activities(client, start_date_utc, end_date_utc) do
    Strava.Paginator.stream(fn pagination ->
      params =
        pagination
        |> Keyword.put(:after, to_epoch(start_date_utc))
        |> Keyword.put(:before, to_epoch(end_date_utc))

      rate_limit_request(fn ->
        Strava.Activities.get_logged_in_athlete_activities(client, params)
      end)
    end)
    |> Enum.to_list()
  end

  def get_activity(client, activity_id, opts \\ []) do
    Cache.cached(activity_id, Strava.DetailedActivity, fn ->
      rate_limit_request(fn ->
        case Strava.Activities.get_activity_by_id(client, activity_id, opts) do
          {:error, %Tesla.Env{status: 404}} -> {:error, :activity_not_found}
          reply -> reply
        end
      end)
    end)
  end

  def athlete_clubs(client) do
    Strava.Paginator.stream(fn pagination ->
      rate_limit_request(fn ->
        Strava.Clubs.get_logged_in_athlete_clubs(client, pagination)
      end)
    end)
    |> Enum.to_list()
  end

  def starred_segments(client) do
    Strava.Paginator.stream(fn pagination ->
      rate_limit_request(fn ->
        Strava.Segments.get_logged_in_athlete_starred_segments(client, pagination)
      end)
    end)
    |> Enum.to_list()
  end

  def get_segment(client, strava_segment_id) do
    rate_limit_request(fn ->
      Strava.Segments.get_segment_by_id(client, strava_segment_id)
    end)
  end

  # Strava rate limits are 600 requests every 15 minutes and limited to 30,000
  # per day, but we enforce a lower limit of 300 requests every 15 minutes to
  # allow other Strava API requests, such as authentication, to succeed and not
  # breach the daily limit.
  #
  # rpm = 30_000 / (24 * 60) = 20.83
  #
  @strava_api "Strava"
  @strava_rate_limit_duration 2_000
  @strava_rate_limit_requests Application.get_env(
                                :segment_challenge,
                                :strava_rate_limit_requests,
                                1
                              )

  # Rate limit requests to Strava to prevent exceeding the API limits.
  defp rate_limit_request(request) when is_function(request, 0) do
    case ExRated.check_rate(@strava_api, @strava_rate_limit_duration, @strava_rate_limit_requests) do
      {:ok, _count} ->
        request.()

      {:error, _limit} ->
        Logger.warn(fn ->
          "Strava API rate limit exceeded, will retry request after #{
            @strava_rate_limit_duration / 1_000
          }s delay."
        end)

        # Wait for rate limit duration, then try again
        :timer.sleep(@strava_rate_limit_duration)

        rate_limit_request(request)
    end
  end

  defp to_epoch(%NaiveDateTime{} = naive_datetime) do
    naive_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
  end

  defp to_epoch(%DateTime{} = datetime), do: DateTime.to_unix(datetime)

  defp update_strava_access(athlete_uuid, %OAuth2.Client{} = client) do
    %OAuth2.Client{
      token: %OAuth2.AccessToken{access_token: access_token, refresh_token: refresh_token}
    } = client

    case StravaAccess.assign_access_token(athlete_uuid, access_token, refresh_token) do
      :ok ->
        :ok

      {:error, error} = reply ->
        Logger.error(fn ->
          "Failed to update Strava access for #{inspect(athlete_uuid)} due to: " <> inspect(error)
        end)

        reply
    end
  end
end
