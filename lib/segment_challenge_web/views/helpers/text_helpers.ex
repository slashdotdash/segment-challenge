defmodule SegmentChallengeWeb.Helpers.TextHelpers do
  def summarize_text(text) do
    text
    |> String.split("\n")
    |> List.first()
  end

  def pluralize(number, singular, plural \\ nil, none \\ nil) do
    plural = plural || "#{singular}s"
    none = none || plural

    pluralized =
      case number do
        0 -> "#{number} #{none}"
        1 -> "#{number} #{singular}"
        _ -> "#{number} #{plural}"
      end

    String.trim(pluralized)
  end

  def blank?(text)
  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(_text), do: false
end
