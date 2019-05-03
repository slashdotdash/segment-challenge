defmodule SegmentChallengeWeb.ChallengeLeaderboardView do
  use SegmentChallengeWeb, :view

  import SegmentChallengeWeb.Helpers.AthleteHelpers
  import SegmentChallengeWeb.Helpers.ChallengeHelpers
  import SegmentChallengeWeb.Helpers.LeaderboardHelpers

  alias SegmentChallenge.Challenges.Formatters.TimeFormatter
  alias SegmentChallenge.Projections.ChallengeLeaderboardProjection
  alias SegmentChallenge.Projections.ChallengeLeaderboardEntryProjection

  def title("show.html", %{challenge: challenge}),
    do: challenge.name <> " leaderboards - Segment Challenge"

  def include_challenge_activities?(%ChallengeLeaderboardProjection{rank_by: "points"}), do: false
  def include_challenge_activities?(%ChallengeLeaderboardProjection{}), do: true

  def challenge_leaderboard_title(conn, %ChallengeLeaderboardProjection{} = leaderboard) do
    %ChallengeLeaderboardProjection{rank_by: rank_by, goal_units: goal_units} = leaderboard

    case rank_by do
      "points" ->
        "Points"

      "goals" ->
        "Progress"

      "elapsed_time_in_seconds" ->
        "Time"

      "distance_in_metres" ->
        "Distance in " <> distance_display_preference(conn, goal_units)

      "moving_time_in_seconds" ->
        "Duration"

      "elevation_gain_in_metres" ->
        "Elevation in " <> elevation_display_preference(conn, goal_units)
    end
  end

  def challenge_leaderboard_rank_by(%ChallengeLeaderboardProjection{} = leaderboard) do
    %ChallengeLeaderboardProjection{rank_by: rank_by} = leaderboard

    case rank_by do
      "points" -> "Points"
      "goals" -> "Progress"
      "elapsed_time_in_seconds" -> "Time"
      "distance_in_metres" -> "Distance"
      "moving_time_in_seconds" -> "Duration"
      "elevation_gain_in_metres" -> "Elevation"
    end
  end

  defp challenge_leaderboard_entry_value(
         conn,
         %ChallengeLeaderboardProjection{} = leaderboard,
         %ChallengeLeaderboardEntryProjection{} = entry,
         stages
       ) do
    %ChallengeLeaderboardProjection{rank_by: rank_by, goal_units: goal_units} = leaderboard

    %ChallengeLeaderboardEntryProjection{
      points: points,
      goals: goals,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      moving_time_in_seconds: moving_time_in_seconds
    } = entry

    case rank_by do
      "points" -> to_string(points)
      "goals" -> "#{goals} / #{length(stages)}"
      "elapsed_time_in_seconds" -> TimeFormatter.elapsed_time(elapsed_time_in_seconds)
      "distance_in_metres" -> format_distance(conn, distance_in_metres, goal_units)
      "moving_time_in_seconds" -> TimeFormatter.duration(moving_time_in_seconds)
      "elevation_gain_in_metres" -> format_elevation(conn, elevation_gain_in_metres, goal_units)
    end
  end
end
