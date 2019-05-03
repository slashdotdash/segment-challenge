defmodule SegmentChallengeWeb.Helpers.NavigationHelpers do
  import SegmentChallengeWeb.Router.Helpers

  def active_section_class(%{assigns: %{active_section: section}}, section), do: "is-active"
  def active_section_class(_conn, _section), do: ""

  def active_challenge_section_class(conn, section) do
    if conn.assigns[:active_challenge_section] == section do
      "is-active"
    end
  end

  def active_dashboard_section_class(%{assigns: %{active_dashboard_section: section}}, section),
    do: "is-active"

  def active_dashboard_section_class(_conn, _section), do: ""

  def active_stage_section_class(conn, section) do
    if conn.assigns[:active_stage_section] == section do
      "is-active"
    end
  end

  def challenge_leaderboard_query_path(conn, leaderboard, challenge, athlete_uuid \\ nil)

  def challenge_leaderboard_query_path(conn, leaderboard, challenge, nil) do
    challenge_leaderboard_path(conn, :show, challenge.url_slug,
      leaderboard: leaderboard.name,
      gender: leaderboard.gender
    )
  end

  def challenge_leaderboard_query_path(conn, leaderboard, challenge, athlete_uuid) do
    challenge_leaderboard_path(conn, :show, challenge.url_slug, athlete_uuid,
      leaderboard: leaderboard.name,
      gender: leaderboard.gender
    )
  end

  def challenge_result_query_path(conn, leaderboard, challenge, athlete_uuid \\ nil)

  def challenge_result_query_path(conn, leaderboard, challenge, nil) do
    challenge_result_path(conn, :show, challenge.url_slug,
      leaderboard: leaderboard.name,
      gender: leaderboard.gender
    )
  end

  def challenge_result_query_path(conn, leaderboard, challenge, athlete_uuid) do
    challenge_result_path(conn, :show, challenge.url_slug, athlete_uuid,
      leaderboard: leaderboard.name,
      gender: leaderboard.gender
    )
  end

  def stage_leaderboard_query_path(conn, leaderboard, challenge, stage, athlete_uuid \\ nil)

  def stage_leaderboard_query_path(conn, leaderboard, challenge, stage, nil) do
    stage_leaderboard_path(conn, :show, challenge.url_slug, stage.url_slug,
      leaderboard: leaderboard.name,
      gender: leaderboard.gender
    )
  end

  def stage_leaderboard_query_path(conn, leaderboard, challenge, stage, athlete_uuid) do
    stage_leaderboard_path(conn, :show, challenge.url_slug, stage.url_slug, athlete_uuid,
      leaderboard: leaderboard.name,
      gender: leaderboard.gender
    )
  end

  def stage_result_query_path(conn, stage_result, challenge, stage, athlete_uuid \\ nil)

  def stage_result_query_path(conn, stage_result, challenge, stage, nil) do
    stage_result_path(conn, :show, challenge.url_slug, stage.url_slug,
      leaderboard: stage_result.name,
      gender: stage_result.gender
    )
  end

  def stage_result_query_path(conn, stage_result, challenge, stage, athlete_uuid) do
    stage_result_path(conn, :show, challenge.url_slug, stage.url_slug, athlete_uuid,
      leaderboard: stage_result.name,
      gender: stage_result.gender
    )
  end
end
