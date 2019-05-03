defmodule SegmentChallenge.Stages.StageEffortMapper do
  alias SegmentChallenge.Athletes.Athlete
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Stages.Stage.Commands.ImportStageEfforts.StageEffort

  @doc """
  Map a given activity to any relevant stage efforts.
  """
  def map_to_stage_efforts(stage, activity)

  def map_to_stage_efforts(
        %StageProjection{stage_type: stage_type} = stage,
        %Strava.DetailedActivity{} = activity
      )
      when stage_type in ["mountain", "flat", "rolling"] do
    %StageProjection{strava_segment_id: strava_segment_id} = stage
    %Strava.DetailedActivity{segment_efforts: segment_efforts} = activity

    segment_efforts
    |> Enum.filter(fn
      %Strava.DetailedSegmentEffort{segment: %Strava.SummarySegment{id: ^strava_segment_id}} ->
        true

      %Strava.DetailedSegmentEffort{} ->
        false
    end)
    |> Enum.map(&map_to_stage_effort(activity, &1))
  end

  def map_to_stage_efforts(
        %StageProjection{stage_type: "race"} = stage,
        %Strava.DetailedActivity{} = activity
      ) do
    case find_best_effort(stage, activity) do
      %Strava.DetailedSegmentEffort{} = segment_effort ->
        map_to_stage_effort(activity, segment_effort)

      nil ->
        map_to_stage_effort(activity)
    end
  end

  def map_to_stage_efforts(
        %StageProjection{stage_type: stage_type},
        %Strava.DetailedActivity{} = activity
      )
      when stage_type in ["distance", "duration", "elevation"] do
    map_to_stage_effort(activity)
  end

  def map_to_stage_efforts(
        %StageProjection{stage_type: stage_type},
        %Strava.SummaryActivity{} = activity
      )
      when stage_type in ["distance", "duration", "elevation"] do
    map_to_stage_effort(activity)
  end

  def map_to_stage_effort(
        %Strava.DetailedActivity{} = activity,
        %Strava.DetailedSegmentEffort{} = segment_effort
      ) do
    %Strava.DetailedActivity{
      type: activity_type,
      trainer: trainer?,
      commute: commute?,
      manual: manual?,
      private: private?,
      flagged: flagged?
    } = activity

    %Strava.DetailedSegmentEffort{
      id: strava_segment_effort_id,
      athlete: %Strava.MetaAthlete{id: strava_athlete_id},
      activity: %Strava.MetaActivity{id: strava_activity_id},
      elapsed_time: elapsed_time_in_seconds,
      start_date: start_date,
      start_date_local: start_date_local,
      distance: distance_in_metres,
      moving_time: moving_time_in_seconds,
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts: device_watts?,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate
    } = segment_effort

    distance_in_metres =
      case distance_in_metres do
        int when is_integer(int) -> int / 1
        float when is_float(float) -> float
      end

    %StageEffort{
      athlete_uuid: Athlete.identity(strava_athlete_id),
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      # Elevation gain be populated from Strava Segment total elevation
      elevation_gain_in_metres: nil,
      start_date: DateTime.to_naive(start_date),
      start_date_local: DateTime.to_naive(start_date_local),
      trainer?: trainer?,
      commute?: commute?,
      manual?: manual?,
      private?: private?,
      flagged?: flagged?,
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts?: device_watts?,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate
    }
  end

  def map_to_stage_effort(%Strava.DetailedActivity{} = activity) do
    %Strava.DetailedActivity{
      id: strava_activity_id,
      athlete: %Strava.MetaAthlete{id: strava_athlete_id},
      type: activity_type,
      distance: distance_in_metres,
      moving_time: moving_time_in_seconds,
      elapsed_time: elapsed_time_in_seconds,
      total_elevation_gain: elevation_gain_in_metres,
      start_date: start_date,
      start_date_local: start_date_local,
      trainer: trainer?,
      commute: commute?,
      manual: manual?,
      private: private?,
      flagged: flagged?,
      average_watts: average_watts,
      device_watts: device_watts?
    } = activity

    %StageEffort{
      athlete_uuid: Athlete.identity(strava_athlete_id),
      strava_activity_id: strava_activity_id,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      start_date: DateTime.to_naive(start_date),
      start_date_local: DateTime.to_naive(start_date_local),
      trainer?: trainer?,
      commute?: commute?,
      manual?: manual?,
      private?: private?,
      flagged?: flagged?,
      average_watts: average_watts,
      device_watts?: device_watts?
    }
  end

  def map_to_stage_effort(%Strava.SummaryActivity{} = activity) do
    %Strava.SummaryActivity{
      id: strava_activity_id,
      athlete: %Strava.MetaAthlete{id: strava_athlete_id},
      type: activity_type,
      distance: distance_in_metres,
      moving_time: moving_time_in_seconds,
      elapsed_time: elapsed_time_in_seconds,
      total_elevation_gain: elevation_gain_in_metres,
      start_date: start_date,
      start_date_local: start_date_local,
      trainer: trainer?,
      commute: commute?,
      manual: manual?,
      private: private?,
      flagged: flagged?,
      average_watts: average_watts,
      device_watts: device_watts?
    } = activity

    %StageEffort{
      athlete_uuid: Athlete.identity(strava_athlete_id),
      strava_activity_id: strava_activity_id,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      start_date: DateTime.to_naive(start_date),
      start_date_local: DateTime.to_naive(start_date_local),
      trainer?: trainer?,
      commute?: commute?,
      manual?: manual?,
      private?: private?,
      flagged?: flagged?,
      average_watts: average_watts,
      device_watts?: device_watts?
    }
  end

  # Find a best effort segment effort that is for at least the stage goal distance.
  defp find_best_effort(%StageProjection{}, %Strava.DetailedActivity{best_efforts: nil}), do: nil
  defp find_best_effort(%StageProjection{}, %Strava.DetailedActivity{best_efforts: []}), do: nil

  defp find_best_effort(%StageProjection{} = stage, %Strava.DetailedActivity{} = activity) do
    %Strava.DetailedActivity{best_efforts: best_efforts} = activity

    goal_distance = StageProjection.goal_distance_in_metres(stage)

    best_efforts
    |> Enum.sort_by(fn %Strava.DetailedSegmentEffort{distance: distance} -> distance end)
    |> Enum.find(fn %Strava.DetailedSegmentEffort{distance: distance} ->
      case Decimal.cmp(distance, goal_distance) do
        :gt -> true
        :eq -> true
        :lt -> false
      end
    end)
  end
end
