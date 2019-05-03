defmodule SegmentChallengeWeb.Helpers.AthleteHelpers do
  alias SegmentChallenge.Challenges.Formatters.TimeFormatter

  def is_current_athlete?(conn, athlete_uuid) do
    case conn.assigns[:current_athlete] do
      nil -> false
      current_athlete -> current_athlete.athlete_uuid == athlete_uuid
    end
  end

  def current_athlete_class(conn, %{athlete_uuid: athlete_uuid}) do
    if is_current_athlete?(conn, athlete_uuid) do
      "is-current-athlete"
    end
  end

  def athlete_name(%{athlete_firstname: firstname, athlete_lastname: lastname}),
    do: "#{firstname} #{lastname}"

  def display_gender("M"), do: "Men"
  def display_gender("F"), do: "Women"
  def display_gender(_gender), do: ""

  def current_athlete_profile(%{assigns: assigns}) do
    case assigns do
      %{current_athlete: %{profile: profile}} -> profile
      _assigns -> ""
    end
  end

  def current_athlete_name(%{assigns: assigns}) do
    case assigns do
      %{current_athlete: %{firstname: firstname, lastname: lastname}} ->
        "#{firstname} #{lastname}"

      _assigns ->
        ""
    end
  end

  def current_athlete_location(%{assigns: assigns}) do
    case assigns do
      %{current_athlete: %{city: city, state: state, country: country}} ->
        [city, state, country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")

      _assigns ->
        ""
    end
  end

  def format_distance(conn, distance_in_metres, units \\ nil)

  def format_distance(conn, distance_in_metres, nil) do
    distance =
      case measurement_preference(conn) do
        :imperial -> distance_in_metres / 1_000 * 0.6213711999983
        :metric -> distance_in_metres / 1_000
      end

    Float.round(distance, 1)
  end

  def format_distance(_conn, distance_in_metres, units) do
    distance =
      case units do
        "feet" -> distance_in_metres * 3.2808
        "miles" -> distance_in_metres / 1_000 * 0.6213711999983
        "metres" -> distance_in_metres
        "kilometres" -> distance_in_metres / 1_000
      end

    Float.round(distance, 1)
  end

  def format_elevation(conn, distance_in_metres, units \\ nil)

  def format_elevation(_conn, nil, _units), do: Phoenix.HTML.raw("&mdash;")

  def format_elevation(conn, distance_in_metres, nil) do
    distance =
      case measurement_preference(conn) do
        :imperial -> distance_in_metres * 3.2808
        :metric -> distance_in_metres
      end

    Float.round(distance, 1)
  end

  def format_elevation(_conn, distance_in_metres, units) do
    distance =
      case units do
        "feet" -> distance_in_metres * 3.2808
        "miles" -> distance_in_metres / 1_000 * 0.6213711999983
        "metres" -> distance_in_metres
        "kilometres" -> distance_in_metres / 1_000
      end

    Float.round(distance, 1)
  end

  def format_duration(duration_in_seconds),
    do: TimeFormatter.duration(duration_in_seconds)

  def format_moving_time(moving_time_in_seconds),
    do: TimeFormatter.moving_time(moving_time_in_seconds)

  def distance_display_preference(conn, units \\ nil)

  def distance_display_preference(conn, nil) do
    case measurement_preference(conn) do
      :imperial -> "miles"
      :metric -> "kilometres"
    end
  end

  def distance_display_preference(_conn, units), do: units

  def elevation_display_preference(conn, units \\ nil)

  def elevation_display_preference(conn, nil) do
    case measurement_preference(conn) do
      :imperial -> "ft"
      :metric -> "metres"
    end
  end

  def elevation_display_preference(_conn, units), do: units

  @doc """
  Return the current athlete's display preferences (`:imperial` or `:metric`).
  """
  def measurement_preference(_conn, default \\ :imperial)

  def measurement_preference(
        %{assigns: %{current_athlete: %{measurement_preference: measurement_preference}}},
        default
      )
      when is_binary(measurement_preference) do
    case measurement_preference do
      imperial when imperial in ["ft", "feet", "miles"] -> :imperial
      metric when metric in ["metres", "meters", "kilometres", "kilometers"] -> :metric
      _preference -> default
    end
  end

  def measurement_preference(_conn, default), do: default
end
