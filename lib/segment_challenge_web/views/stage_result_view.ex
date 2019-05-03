defmodule SegmentChallengeWeb.StageResultView do
  use SegmentChallengeWeb, :view

  alias SegmentChallenge.Challenges.Formatters.TimeFormatter
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.StageResultEntryProjection

  def title("show.html", %{stage: stage}), do: stage.name <> " results - Segment Challenge"

  def render("scripts.publish.html", %{stage: stage}) do
    """
    <script type="text/javascript">
    SegmentChallenge.renderMarkdownEditor('stage-results-markdown', {
      label: 'Provide a summary of the stage',
      name: 'message',
      markdown: `#{String.replace(stage.results_markdown || "", "`", "\\`")}`,
      rowCount: 15
    })
    </script>)
    """
    |> raw()
  end

  def display_rank_by(rank_by)
  def display_rank_by("points"), do: "Points"
  def display_rank_by("goals"), do: "Completed stages"
  def display_rank_by("elapsed_time_in_seconds"), do: "Time"
  def display_rank_by("moving_time_in_seconds"), do: "Duration"
  def display_rank_by("distance_in_metres"), do: "Distance"
  def display_rank_by("elevation_gain_in_metres"), do: "Elevation"

  def display_rank_by_value(conn, rank_by, %StageResultEntryProjection{} = entry) do
    %StageResultEntryProjection{
      points: points,
      goals: goals,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres
    } = entry

    case rank_by do
      "points" -> to_string(points)
      "goals" -> to_string(goals)
      "elapsed_time_in_seconds" -> TimeFormatter.elapsed_time(elapsed_time_in_seconds)
      "moving_time_in_seconds" -> TimeFormatter.duration(moving_time_in_seconds)
      "distance_in_metres" -> format_distance(conn, distance_in_metres)
      "elevation_gain_in_metres" -> format_elevation(conn, elevation_gain_in_metres)
    end
  end

  def display_rank_by_value_gain(conn, rank_by, %StageResultEntryProjection{} = entry) do
    %StageResultEntryProjection{
      points_gained: points_gained,
      goals_gained: goals_gained,
      elapsed_time_in_seconds_gained: elapsed_time_in_seconds_gained,
      moving_time_in_seconds_gained: moving_time_in_seconds_gained,
      distance_in_metres_gained: distance_in_metres_gained,
      elevation_gain_in_metres_gained: elevation_gain_in_metres_gained
    } = entry

    case rank_by do
      "points" ->
        display_positive_gain(points_gained)

      "goals" ->
        display_positive_gain(goals_gained)

      "elapsed_time_in_seconds" ->
        display_positive_gain(elapsed_time_in_seconds_gained, &TimeFormatter.elapsed_time/1)

      "moving_time_in_seconds" ->
        display_positive_gain(moving_time_in_seconds_gained, &TimeFormatter.duration/1)

      "distance_in_metres" ->
        display_positive_gain(distance_in_metres_gained, &format_distance(conn, &1))

      "elevation_gain_in_metres" ->
        display_positive_gain(elevation_gain_in_metres_gained, &format_elevation(conn, &1))
    end
  end

  defp display_positive_gain(value, formatter \\ fn value -> value end) do
    if value > 0 do
      "+" <> to_string(formatter.(value))
    else
      ""
    end
  end
end
