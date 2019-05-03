defmodule SegmentChallenge.Projections.StageEffortProjector do
  use Commanded.Projections.Ecto, name: "StageEffortProjector"
  use SegmentChallenge.Stages.Stage.Aliases

  alias SegmentChallenge.Challenges.Formatters.SpeedFormatter
  alias SegmentChallenge.Projections.StageEffortProjection

  project %StageEffortRecorded{} = event, fn multi ->
    %StageEffortRecorded{
      stage_uuid: stage_uuid,
      athlete_uuid: athlete_uuid,
      athlete_gender: athlete_gender,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      start_date: start_date,
      start_date_local: start_date_local,
      trainer?: trainer,
      commute?: commute,
      manual?: manual,
      private?: private,
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts?: device_watts,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate
    } = event

    stage_effort = %StageEffortProjection{
      stage_uuid: stage_uuid,
      athlete_uuid: athlete_uuid,
      athlete_gender: athlete_gender,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      activity_type: activity_type,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      start_date: start_date,
      start_date_local: start_date_local,
      trainer: trainer,
      commute: commute,
      manual: manual,
      private: private,
      flagged: false,
      speed_in_mph: SpeedFormatter.speed_in_mph(distance_in_metres, elapsed_time_in_seconds),
      speed_in_kph: SpeedFormatter.speed_in_kph(distance_in_metres, elapsed_time_in_seconds),
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts: device_watts,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate
    }

    Ecto.Multi.insert(multi, :stage_effort, stage_effort)
  end

  project %StageEffortRemoved{} = event, fn multi ->
    %StageEffortRemoved{
      stage_uuid: stage_uuid,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = event

    Ecto.Multi.delete_all(
      multi,
      :stage_effort,
      stage_effort_query(stage_uuid, strava_activity_id, strava_segment_effort_id),
      []
    )
  end

  project %StageEffortFlagged{} = event, fn multi ->
    %StageEffortFlagged{
      stage_uuid: stage_uuid,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      reason: reason
    } = event

    Ecto.Multi.update_all(
      multi,
      :stage_effort,
      stage_effort_query(stage_uuid, strava_activity_id, strava_segment_effort_id),
      set: [
        flagged: true,
        flagged_reason: reason
      ]
    )
  end

  project %CompetitorRemovedFromStage{} = event, fn multi ->
    %CompetitorRemovedFromStage{stage_uuid: stage_uuid, athlete_uuid: athlete_uuid} = event

    Ecto.Multi.delete_all(
      multi,
      :stage_effort,
      athlete_stage_effort_query(stage_uuid, athlete_uuid),
      []
    )
  end

  project %StageEffortsCleared{} = event, fn multi ->
    %StageEffortsCleared{stage_uuid: stage_uuid} = event

    Ecto.Multi.delete_all(
      multi,
      :stage_effort,
      stage_effort_query(stage_uuid),
      []
    )
  end

  defp athlete_stage_effort_query(stage_uuid, athlete_uuid) do
    from(se in StageEffortProjection,
      where: se.stage_uuid == ^stage_uuid and se.athlete_uuid == ^athlete_uuid
    )
  end

  defp stage_effort_query(stage_uuid) do
    from(se in StageEffortProjection,
      where: se.stage_uuid == ^stage_uuid
    )
  end

  defp stage_effort_query(stage_uuid, strava_activity_id, strava_segment_effort_id)

  defp stage_effort_query(stage_uuid, strava_activity_id, nil) do
    from(se in StageEffortProjection,
      where:
        se.stage_uuid == ^stage_uuid and se.strava_activity_id == ^strava_activity_id and
          is_nil(se.strava_segment_effort_id)
    )
  end

  defp stage_effort_query(stage_uuid, strava_activity_id, strava_segment_effort_id) do
    from(se in StageEffortProjection,
      where:
        se.stage_uuid == ^stage_uuid and se.strava_activity_id == ^strava_activity_id and
          se.strava_segment_effort_id == ^strava_segment_effort_id
    )
  end
end
