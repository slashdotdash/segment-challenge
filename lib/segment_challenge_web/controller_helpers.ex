defmodule SegmentChallengeWeb.ControllerHelpers do
  import Plug.Conn
  import SegmentChallengeWeb.Router.Helpers

  def set_active_section(conn, section) do
    assign(conn, :active_section, section)
  end

  def set_active_challenge_section(conn, section) do
    assign(conn, :active_challenge_section, section)
  end

  def set_active_dashboard_section(conn, section) do
    assign(conn, :active_dashboard_section, section)
  end

  def set_active_stage_section(conn, section) do
    assign(conn, :active_stage_section, section)
  end

  def current_athlete_uuid(%{assigns: %{current_athlete: %{athlete_uuid: athlete_uuid}}}),
    do: athlete_uuid

  def current_athlete_uuid(_conn), do: nil

  def current_athlete_name(%{
        assigns: %{current_athlete: %{firstname: firstname, lastname: lastname}}
      }),
      do: "#{firstname} #{lastname}"

  def current_athlete_name(_conn), do: nil

  def include_script(%{assigns: %{scripts: scripts}} = conn, script) do
    assign(conn, :scripts, scripts ++ [static_path(conn, script)])
  end
end
