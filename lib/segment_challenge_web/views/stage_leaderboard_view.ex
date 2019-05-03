defmodule SegmentChallengeWeb.StageLeaderboardView do
  use SegmentChallengeWeb, :view

  import SegmentChallengeWeb.Helpers.AthleteHelpers
  import SegmentChallengeWeb.Helpers.ChallengeHelpers
  import SegmentChallengeWeb.Helpers.LeaderboardHelpers
  import SegmentChallengeWeb.Helpers.StageHelpers

  alias SegmentChallenge.Challenges.Formatters.TimeFormatter
  alias SegmentChallenge.Projections.StageEffortProjection
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardEntryProjection

  def title("show.html", %{stage: stage}), do: stage.name <> " leaderboards - Segment Challenge"

  def flag_stage_efforts?(conn, %StageProjection{status: "active"}, challenge),
    do: is_challenge_host?(conn, challenge)

  def flag_stage_efforts?(_conn, _stage, _challenge), do: false

  def is_best_stage_effort?(stage_effort, entry) do
    stage_effort.strava_activity_id == entry.strava_activity_id &&
      stage_effort.strava_segment_effort_id == entry.strava_segment_effort_id
  end

  def stage_effort_class(%StageEffortProjection{flagged: true}, _opts), do: "is-flagged"
  def stage_effort_class(%StageEffortProjection{}, _opts), do: ""

  def display_distance(conn, %StageLeaderboardProjection{} = leaderboard, distance_in_metres) do
    %StageLeaderboardProjection{
      rank_by: rank_by,
      goal_measure: goal_measure,
      goal_units: goal_units
    } = leaderboard

    case {rank_by, goal_measure} do
      {"distance_in_metres", _goal_measure} ->
        raw("<strong>#{format_distance(conn, distance_in_metres, goal_units)}</strong>")

      {_rank_by, "distance_in_metres"} ->
        format_distance(conn, distance_in_metres, goal_units)

      {_rank_by, _goal_measure} ->
        format_distance(conn, distance_in_metres)
    end
  end

  def display_moving_time(%StageLeaderboardProjection{} = leaderboard, moving_time_in_seconds) do
    %StageLeaderboardProjection{rank_by: rank_by} = leaderboard

    case rank_by do
      "moving_time_in_seconds" ->
        raw("<strong>#{TimeFormatter.moving_time(moving_time_in_seconds)}</strong>")

      _rank_by ->
        TimeFormatter.moving_time(moving_time_in_seconds)
    end
  end

  def display_elevation(
        conn,
        %StageLeaderboardProjection{} = leaderboard,
        elevation_gain_in_metres
      ) do
    %StageLeaderboardProjection{rank_by: rank_by, goal_units: goal_units} = leaderboard

    case rank_by do
      "elevation_gain_in_metres" ->
        raw("<strong>#{format_elevation(conn, elevation_gain_in_metres, goal_units)}</strong>")

      _rank_by ->
        format_elevation(conn, elevation_gain_in_metres)
    end
  end

  def display_speed(conn, %StageLeaderboardEntryProjection{} = entry) do
    %StageLeaderboardEntryProjection{speed_in_kph: speed_in_kph, speed_in_mph: speed_in_mph} =
      entry

    case measurement_preference(conn) do
      :imperial -> display_speed_in_units(speed_in_mph, "mi/h", "Miles per hour")
      :metric -> display_speed_in_units(speed_in_kph, "km/h", "Kilometres per hour")
    end
  end

  def display_speed(conn, %StageEffortProjection{} = stage_effort) do
    %StageEffortProjection{speed_in_kph: speed_in_kph, speed_in_mph: speed_in_mph} = stage_effort

    case measurement_preference(conn) do
      :imperial -> display_speed_in_units(speed_in_mph, "mi/h", "Miles per hour")
      :metric -> display_speed_in_units(speed_in_kph, "km/h", "Kilometres per hour")
    end
  end

  def display_pace(conn, %StageLeaderboardEntryProjection{} = entry) do
    %StageLeaderboardEntryProjection{speed_in_kph: speed_in_kph, speed_in_mph: speed_in_mph} =
      entry

    case measurement_preference(conn) do
      :imperial -> display_pace_in_units(speed_in_mph, "mi")
      :metric -> display_pace_in_units(speed_in_kph, "km")
    end
  end

  def display_pace(conn, %StageEffortProjection{} = stage_effort) do
    %StageEffortProjection{speed_in_kph: speed_in_kph, speed_in_mph: speed_in_mph} = stage_effort

    case measurement_preference(conn) do
      :imperial -> display_pace_in_units(speed_in_mph, "mi")
      :metric -> display_pace_in_units(speed_in_kph, "km")
    end
  end

  def distance_title(conn, %StageLeaderboardProjection{} = leaderboard) do
    %StageLeaderboardProjection{rank_by: rank_by, goal_units: goal_units} = leaderboard

    case rank_by do
      "distance_in_metres" ->
        "Distance in " <> distance_display_preference(conn, goal_units)

      _rank_by ->
        "Distance in " <> distance_display_preference(conn)
    end
  end

  def elevation_title(conn, %StageLeaderboardProjection{} = leaderboard) do
    %StageLeaderboardProjection{rank_by: rank_by, goal_units: goal_units} = leaderboard

    case rank_by do
      "elevation_gain_in_metres" ->
        "Elevation in " <> elevation_display_preference(conn, goal_units)

      _rank_by ->
        "Elevation in " <> elevation_display_preference(conn)
    end
  end

  defp display_speed_in_units(speed, units, title) when is_float(speed) do
    raw("""
    #{round(speed, 1)}<small><abbr title="#{title}">#{units}</abbr></small>
    """)
  end

  defp display_speed_in_units(_speed, _units, _title), do: raw("&mdash;")

  defp display_pace_in_units(0.0, units), do: "0:00/#{units}"

  defp display_pace_in_units(speed, units) do
    pace = 60 / speed
    minutes = pace |> Float.floor() |> round()
    seconds = round((pace - minutes) * 60) |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{minutes}:#{seconds}/#{units}"
  end
end
