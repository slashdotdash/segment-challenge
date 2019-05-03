defmodule SegmentChallenge.Challenges.Formatters.TimeFormatter do
  use Timex

  def duration(elapsed_in_seconds) do
    elapsed_in_seconds
    |> Timex.Duration.from_seconds()
    |> Timex.format_duration(:humanized)
  end

  def elapsed_time(elapsed_time_in_seconds) do
    hours = div(elapsed_time_in_seconds, 3600)
    minutes = rem(elapsed_time_in_seconds, 3600) |> div(60)
    seconds = rem(elapsed_time_in_seconds, 60)

    case {hours, minutes} do
      {0, 0} -> "#{seconds}s"
      {0, _minutes} -> "#{minutes}:#{pad(seconds)}"
      {_hours, _minutes} -> "#{hours}:#{pad(minutes)}:#{pad(seconds)}"
    end
  end

  @doc """
  Display moving time, such as "1d 15h 40m 21s"
  """
  def moving_time(moving_time_in_seconds) do
    days = div(moving_time_in_seconds, 86400)
    hours = rem(moving_time_in_seconds, 86400) |> div(3600)
    minutes = rem(moving_time_in_seconds, 3600) |> div(60)
    seconds = rem(moving_time_in_seconds, 60)

    case {days, hours, minutes, seconds} do
      {0, 0, 0, seconds} -> "#{seconds}s"
      {0, 0, minutes, seconds} -> "#{minutes}m #{seconds}s"
      {0, hours, minutes, seconds} -> "#{hours}h #{minutes}m #{seconds}s"
      {days, hours, minutes, seconds} -> "#{days}d #{hours}h #{minutes}m #{seconds}s"
    end
  end

  defp pad(integer) do
    integer |> Integer.to_string() |> String.pad_leading(2, "0")
  end
end
