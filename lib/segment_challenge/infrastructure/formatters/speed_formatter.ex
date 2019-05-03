defmodule SegmentChallenge.Challenges.Formatters.SpeedFormatter do
  def speed_in_mph(_distance_in_metres, 0), do: 0.0
  def speed_in_mph(0.0, _duration_in_seconds), do: 0.0

  def speed_in_mph(distance_in_metres, duration_in_seconds) do
    speed_in_kph(distance_in_metres, duration_in_seconds) / 1.60934
  end

  def speed_in_kph(_distance_in_metres, 0), do: 0.0
  def speed_in_kph(0.0, _duration_in_seconds), do: 0.0

  def speed_in_kph(distance_in_metres, duration_in_seconds) do
    distance_in_metres / 1_000 / (duration_in_seconds / 60 / 60)
  end
end
