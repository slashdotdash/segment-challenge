defmodule SegmentChallenge.StorageCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Application.stop(:segment_challenge)
    :ok = Application.stop(:commanded)
    :ok = Application.stop(:eventstore)

    reset_eventstore()
    reset_readstore()

    {:ok, _} = Application.ensure_all_started(:segment_challenge)

    :ok
  end

  defp reset_eventstore do
    config = EventStore.Config.parsed() |> EventStore.Config.default_postgrex_opts()

    {:ok, conn} = Postgrex.start_link(config)

    EventStore.Storage.Initializer.reset!(conn)
  end

  defp reset_readstore do
    readstore_config = Application.get_env(:segment_challenge, SegmentChallenge.Repo)

    {:ok, conn} = Postgrex.start_link(readstore_config)

    Postgrex.query!(conn, truncate_readstore_tables(), [])
  end

  defp truncate_readstore_tables do
    """
    TRUNCATE TABLE
      projection_versions,
      activity_feed_activities,
      activity_feed_actors,
      athlete_badges,
      athlete_club_memberships,
      athlete_competitors,
      challenges,
      challenge_competitors,
      challenge_leaderboard_entries,
      challenge_leaderboards,
      challenge_limited_competitors,
      clubs,
      email_notification_settings,
      emails,
      profiles,
      stages,
      stage_leaderboard_entries,
      stage_leaderboard_rankings,
      stage_leaderboards,
      stage_result_challenge_leaderboards,
      stage_result_challenge_stages,
      stage_results,
      stage_result_entries,
      strava_cache,
      url_slugs
    RESTART IDENTITY;
    """
  end
end
