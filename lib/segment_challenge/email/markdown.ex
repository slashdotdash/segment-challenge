defmodule SegmentChallenge.Challenges.Services.Markdown do
  def markdown_to_html(nil), do: nil
  def markdown_to_html(""), do: ""

  def markdown_to_html(markdown) do
    Cmark.to_html(markdown, [:smart, :safe])
  end
end
