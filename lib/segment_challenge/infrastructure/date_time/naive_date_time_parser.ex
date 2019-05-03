defmodule SegmentChallenge.NaiveDateTimeParser do
  def from_iso8601!(date) do
    date |> NaiveDateTime.from_iso8601!() |> NaiveDateTime.truncate(:second)
  end
end
