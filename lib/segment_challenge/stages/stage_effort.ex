defmodule SegmentChallenge.Stages.Stage.StageEffort do
  alias SegmentChallenge.Stages.Stage.StageEffort

  @derive Jason.Encoder
  defstruct [
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
    :trainer?,
    :commute?,
    :manual?,
    :private?,
    :flagged?,
    :average_cadence,
    :average_watts,
    :device_watts?,
    :average_heartrate,
    :max_heartrate
  ]

  def count_by_athlete(stage_efforts, athlete_uuid) do
    stage_efforts
    |> Enum.filter(&is_athlete?(&1, athlete_uuid))
    |> Enum.count()
  end

  def is_athlete?(%StageEffort{athlete_uuid: athlete_uuid}, athlete_uuid), do: true
  def is_athlete?(%StageEffort{}, _athlete_uuid), do: false

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
end
