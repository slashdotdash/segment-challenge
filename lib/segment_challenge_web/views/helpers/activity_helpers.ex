defmodule SegmentChallengeWeb.Helpers.ActivityHelpers do
  import SegmentChallenge.Challenges.Formatters.TimeFormatter
  import SegmentChallengeWeb.Router.Helpers

  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection
  alias SegmentChallengeWeb.Helpers.AthleteHelpers
  alias SegmentChallengeWeb.Helpers.GoalHelpers
  alias SegmentChallengeWeb.Helpers.UnitHelpers

  def has_actor_image?(%{actor_image: nil}), do: false
  def has_actor_image?(%{actor_image: "avatar/athlete/large.png"}), do: false
  def has_actor_image?(%{actor_type: "athlete"}), do: true
  def has_actor_image?(%{actor_type: "club"}), do: true
  def has_actor_image?(_activity), do: false

  def actor_image(%{actor_image: actor_image}), do: actor_image

  def render_activity_message(conn, activity)

  def render_activity_message(
        conn,
        %ActivityProjection{verb: "attempt", object_type: "stage", metadata: metadata}
      )
      when map_size(metadata) > 0 do
    %{
      "activity_type" => activity_type,
      "distance_in_metres" => distance_in_metres,
      "elapsed_time_in_seconds" => elapsed_time_in_seconds,
      "elevation_gain_in_metres" => elevation_gain_in_metres,
      "moving_time_in_seconds" => moving_time_in_seconds,
      "stage_name" => stage_name,
      "stage_type" => stage_type,
      "stage_uuid" => stage_uuid
    } = metadata

    stage_link = "<a href=\"#{redirect_path(conn, :stage, stage_uuid)}\">#{stage_name}</a>"

    message =
      case stage_type do
        "race" ->
          "Recorded a time for " <>
            stage_name <> " of <strong>" <> elapsed_time(elapsed_time_in_seconds) <> "</strong>"

        segment when segment in ["mountain", "rolling", "flat"] ->
          "Recorded an attempt at stage " <>
            stage_link <> " of <strong>" <> elapsed_time(elapsed_time_in_seconds) <> "</strong>"

        "distance" ->
          "Recorded a " <>
            activity_description(activity_type) <>
            " activity for stage " <>
            stage_link <> " of " <> display_distance_units(conn, distance_in_metres)

        "elevation" ->
          "Recorded a " <>
            activity_description(activity_type) <>
            " activity for stage " <>
            stage_name <> " climbing " <> display_distance_units(conn, elevation_gain_in_metres)

        "duration" ->
          "Recorded a " <>
            activity_description(activity_type) <>
            " activity for stage " <> stage_link <> " of " <> duration(moving_time_in_seconds)
      end

    Phoenix.HTML.raw(message)
  end

  def render_activity_message(
        conn,
        %ActivityProjection{verb: verb, object_type: "stage", metadata: metadata}
      )
      when verb in ["achieved", "completed"] and map_size(metadata) > 0 do
    %{
      "stage_uuid" => stage_uuid,
      "stage_name" => stage_name,
      "goal" => goal,
      "goal_units" => goal_units
    } = metadata

    stage_link = """
    <a href="#{redirect_path(conn, :stage, stage_uuid)}">#{stage_name}</a>
    """

    message =
      case Map.get(metadata, "stage_type") do
        "race" ->
          "Completed " <>
            stage_link <>
            " distance of #{GoalHelpers.display_goal(goal)} " <>
            UnitHelpers.display_units(goal_units)

        _stage_type ->
          "Achieved stage " <>
            stage_link <>
            " goal of #{GoalHelpers.display_goal(goal)} " <>
            UnitHelpers.display_units(goal_units)
      end

    Phoenix.HTML.raw(message)
  end

  def render_activity_message(_conn, %ActivityProjection{} = activity) do
    %ActivityProjection{message: message} = activity

    message
  end

  defp activity_description("Ride"), do: "ride"
  defp activity_description("Run"), do: "run"
  defp activity_description("Hike"), do: "hike"
  defp activity_description("Swim"), do: "swim"
  defp activity_description("VirtualRide"), do: "virtual ride"
  defp activity_description("VirtualRun"), do: "virtual run"
  defp activity_description("Walk"), do: "walk"
  defp activity_description(nil), do: "unknown"
  defp activity_description(activity_type), do: String.downcase(activity_type)

  def display_distance_units(conn, distance_in_metres) do
    {distance, units} =
      case AthleteHelpers.measurement_preference(conn) do
        :imperial when distance_in_metres < 1_609 -> {distance_in_metres * 3.28084, "ft"}
        :imperial -> {distance_in_metres / 1_000 * 0.6213711999983, " miles"}
        :metric when distance_in_metres < 1_000 -> {distance_in_metres, " metres"}
        :metric -> {distance_in_metres / 1_000, "km"}
      end

    (distance |> Float.round(1) |> Float.to_string()) <> units
  end
end
