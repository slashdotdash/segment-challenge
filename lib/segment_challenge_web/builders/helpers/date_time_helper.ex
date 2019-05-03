defmodule SegmentChallengeWeb.Builders.DateTimeHelper do
  def parse_date_time(params, key) do
    Map.update(params, key, nil, &date_from_iso8601/1)
  end

  def date_from_iso8601(""), do: nil
  def date_from_iso8601(date) do
    case NaiveDateTime.from_iso8601(date) do
      {:ok, parsed} -> parsed
      {:error, _reason} -> date
    end
  end
end
