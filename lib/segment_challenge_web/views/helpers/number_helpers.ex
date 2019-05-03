defmodule SegmentChallengeWeb.Helpers.NumberHelpers do
  def round(number, precision) do
    Float.round(number, precision)
  end
end
