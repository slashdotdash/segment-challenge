defmodule SegmentChallengeWeb.Helpers.DateTimeHelpers do
  use Timex

  alias SegmentChallenge.Challenges.Formatters.TimeFormatter

  def format_date(date, format \\ "%B %e, %Y") do
    Timex.format!(date, format, :strftime)
  end

  def format_date_time(datetime, format \\ "%B %e, %Y at %l:%M%P") do
    Timex.format!(datetime, format, :strftime)
  end

  @doc """
  Display a UTC datetime using a `<time />` HTML tag.

  ## Format

    "YYYY-MM-DDThh:mm:ssTZD"

    - YYYY - year (e.g. 2011)
    - MM - month (e.g. 01 for January)
    - DD - day of the month (e.g. 08)
    - T - a required separator if time is also specified
    - hh - hour (e.g. 22 for 10.00pm)
    - mm - minutes (e.g. 55)
    - ss - seconds (e.g. 03)
    - TZD - Time Zone Designator (Z denotes Zulu, also known as Greenwich Mean Time)

  """
  def date_time_tag(datetime, format \\ "%B %e, %Y at %l:%M%P") do
    display = Timex.format!(datetime, format, :strftime)
    time = Timex.format!(datetime, "%Y-%0m-%0dT%H:%M:%SZ", :strftime)

    Phoenix.HTML.raw("""
    <time datetime="#{time}">#{display} UTC</time>
    """)
  end

  def from_now(date) do
    Timex.from_now(date)
  end

  @doc """
  Calculate difference between the given date and now in the specified units.
  units
    :years :months :weeks :days :hours :mins :secs :timestamp
  """
  def date_diff(to, units) do
    Timex.diff(Timex.now(), to, units) |> abs |> max(0)
  end

  @date_diff_granularity [:months, :days, :hours, :minutes, :seconds]

  def date_diff(to) do
    granularity =
      Enum.find(@date_diff_granularity, fn granularity ->
        date_diff(to, granularity) > 1
      end)

    case date_diff(to, granularity) do
      1 -> "1 #{singular(granularity)}"
      diff -> "#{diff} #{granularity}"
    end
  end

  def singular(:months), do: "month"
  def singular(:days), do: "day"
  def singular(:hours), do: "hour"
  def singular(:minutes), do: "minute"
  def singular(:seconds), do: "second"

  defdelegate elapsed_time(elapsed_time_in_seconds), to: TimeFormatter

  def time_remaining(date) do
    now = NaiveDateTime.utc_now()

    if Timex.after?(date, now) do
      case Timex.diff(date, now, :days) do
        0 ->
          case Timex.diff(date, now, :hours) do
            0 ->
              case Timex.diff(date, now, :minutes) do
                0 -> "0"
                1 -> "1 minutes"
                minutes -> "#{minutes} minutes"
              end

            1 ->
              "1 hour"

            hours ->
              "#{hours} hours"
          end

        1 ->
          "1 day"

        days ->
          "#{days} days"
      end
    else
      "0"
    end
  end
end
