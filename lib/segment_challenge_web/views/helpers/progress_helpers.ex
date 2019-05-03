defmodule SegmentChallengeWeb.Helpers.ProgressHelpers do
  @one_hundred_percent Decimal.new(100)

  def progress_bar(progress, precision \\ 0)

  def progress_bar(%Decimal{} = progress, precision) do
    value = Decimal.round(progress, precision)

    class = if progress_completed?(progress), do: "progress is-primary", else: "progress"

    html = """
    <progress class="#{class}" value="#{value}" max="100">#{value}%</progress>
    """

    {:safe, html}
  end

  def progress_bar(nil, _precision), do: ""

  def progress_completed?(%Decimal{} = progress) do
    case Decimal.cmp(progress, @one_hundred_percent) do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  end

  def progress_completed?(nil), do: false
end
