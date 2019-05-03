defmodule SegmentChallengeWeb.Helpers.UnitHelpers do
  def display_units("kilometres"), do: "km"
  def display_units("feet"), do: "ft"
  def display_units(units), do: units
end
