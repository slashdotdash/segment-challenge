defmodule SegmentChallenge.Leaderboards.StageLeaderboard.StageEffort do
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageEffort

  @derive Jason.Encoder
  defstruct [
    :rank,
    :athlete_uuid,
    :athlete_gender,
    :strava_activity_id,
    :strava_segment_effort_id,
    :activity_type,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :start_date,
    :start_date_local,
    :average_cadence,
    :average_watts,
    :device_watts?,
    :average_heartrate,
    :max_heartrate,
    :goal_progress,
    :stage_effort_count,
    private?: false
  ]

  def is_gender?(%StageEffort{athlete_gender: gender}, gender), do: true
  def is_gender?(%StageEffort{}, _gender), do: false

  def achieved_goal?(%StageEffort{} = stage_effort, measure, %Decimal{} = goal) do
    value =
      case Map.get(stage_effort, measure) do
        number when is_integer(number) -> Decimal.new(number)
        number when is_float(number) -> Decimal.from_float(number)
        nil -> Decimal.new(0)
      end

    case Decimal.cmp(value, goal) do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  end

  def goal_progress(%StageEffort{} = stage_effort, measure, %Decimal{} = goal) do
    value =
      case Map.get(stage_effort, measure) do
        number when is_integer(number) -> Decimal.new(number)
        number when is_float(number) -> Decimal.from_float(number)
        nil -> Decimal.new(0)
      end

    value |> Decimal.div(goal) |> Decimal.mult(Decimal.new(100))
  end

  def accumulate(stage_efforts) when is_list(stage_efforts) do
    device_watts? =
      Enum.all?(stage_efforts, fn %StageEffort{device_watts?: device_watts?} -> device_watts? end)

    max_heart_rate =
      stage_efforts
      |> Enum.map(fn %StageEffort{average_heartrate: average_heartrate} -> average_heartrate end)
      |> Enum.max()

    [latest_effort | _stage_efforts] = sort_by_start_date(stage_efforts)

    %StageEffort{
      latest_effort
      | elapsed_time_in_seconds: sum(stage_efforts, :elapsed_time_in_seconds, 0),
        moving_time_in_seconds: sum(stage_efforts, :moving_time_in_seconds, 0),
        distance_in_metres: sum(stage_efforts, :distance_in_metres, 0.0),
        elevation_gain_in_metres: sum(stage_efforts, :elevation_gain_in_metres, 0.0),
        average_cadence: avg(stage_efforts, :average_cadence, nil),
        average_watts: avg(stage_efforts, :average_watts, nil),
        device_watts?: device_watts?,
        average_heartrate: avg(stage_efforts, :average_heartrate, nil),
        max_heartrate: max_heart_rate
    }
  end

  defp sort_by_start_date(stage_efforts) do
    Enum.sort_by(
      stage_efforts,
      fn %StageEffort{start_date: start_date} -> map_to_epoch(start_date) end,
      &>=/2
    )
  end

  @epoch ~N[1970-01-01 00:00:00]

  defp map_to_epoch(%NaiveDateTime{} = datetime), do: NaiveDateTime.diff(datetime, @epoch)

  defp sum(stage_efforts, field, default) do
    stage_efforts
    |> Enum.map(&Map.get(&1, field, default))
    |> Enum.reduce(default, fn
      nil, nil -> nil
      nil, acc -> acc
      value, nil -> value
      value, acc -> acc + value
    end)
  end

  defp avg(stage_efforts, field, default) do
    case sum(stage_efforts, field, default) do
      ^default -> default
      total -> total / length(stage_efforts)
    end
  end
end
