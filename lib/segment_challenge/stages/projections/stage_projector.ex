defmodule SegmentChallenge.Projections.StageProjector do
  use Commanded.Projections.Ecto,
    name: "StageProjection",
    consistency: :strong

  use SegmentChallenge.Stages.Stage.Aliases

  import SegmentChallenge.Challenges.Services.Markdown, only: [markdown_to_html: 1]

  alias SegmentChallenge.Projections.StageProjection

  project %StageCreated{} = event, fn multi ->
    %StageCreated{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      stage_type: stage_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      included_activity_types: included_activity_types,
      allow_private_activities?: allow_private_activities,
      accumulate_activities?: accumulate_activities,
      visible?: visible,
      url_slug: url_slug,
      created_by_athlete_uuid: created_by_athlete_uuid
    } = event

    stage = %StageProjection{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      stage_number: stage_number,
      stage_type: stage_type,
      name: name,
      description_markdown: description,
      description_html: markdown_to_html(description),
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      included_activity_types: included_activity_types,
      allow_private_activities: allow_private_activities,
      accumulate_activities: accumulate_activities,
      visible: visible,
      url_slug: url_slug,
      created_by_athlete_uuid: created_by_athlete_uuid,
      status: "upcoming"
    }

    Ecto.Multi.insert(multi, :stage, stage)
  end

  project %StageSegmentConfigured{} = event, fn multi ->
    %StageSegmentConfigured{
      stage_uuid: stage_uuid,
      strava_segment_id: strava_segment_id,
      start_description: start_description,
      end_description: end_description,
      distance_in_metres: distance_in_metres,
      average_grade: average_grade,
      maximum_grade: maximum_grade,
      start_latlng: [start_latitude, start_longitude],
      end_latlng: [end_latitude, end_longitude],
      map_polyline: map_polyline
    } = event

    update_stage(multi, stage_uuid,
      set: [
        strava_segment_id: strava_segment_id,
        start_description_html: markdown_to_html(start_description),
        end_description_html: markdown_to_html(end_description),
        distance_in_metres: distance_in_metres,
        average_grade: average_grade,
        maximum_grade: maximum_grade,
        start_latitude: start_latitude,
        start_longitude: start_longitude,
        end_latitude: end_latitude,
        end_longitude: end_longitude,
        map_polyline: map_polyline
      ]
    )
  end

  project %StageGoalConfigured{} = event, fn multi ->
    %StageGoalConfigured{stage_uuid: stage_uuid, goal: goal, goal_units: goal_units} = event

    update_stage(multi, stage_uuid, set: [has_goal: true, goal: goal, goal_units: goal_units])
  end

  project %StageDescriptionEdited{} = event, fn multi ->
    %StageDescriptionEdited{stage_uuid: stage_uuid, description: description} = event

    update_stage(multi, stage_uuid,
      set: [description_markdown: description, description_html: markdown_to_html(description)]
    )
  end

  project %StageDurationAdjusted{} = event, fn multi ->
    %StageDurationAdjusted{
      stage_uuid: stage_uuid,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = event

    update_stage(multi, stage_uuid,
      set: [
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local
      ]
    )
  end

  project %StageIncludedActivitiesAdjusted{} = event, fn multi ->
    %StageIncludedActivitiesAdjusted{
      stage_uuid: stage_uuid,
      included_activity_types: included_activity_types
    } = event

    update_stage(multi, stage_uuid, set: [included_activity_types: included_activity_types])
  end

  project %StageStarted{} = event, fn multi ->
    %StageStarted{stage_uuid: stage_uuid} = event

    update_stage(multi, stage_uuid, set: [status: "active", visible: true])
  end

  project %StageRevealed{} = event, fn multi ->
    %StageRevealed{stage_uuid: stage_uuid} = event

    update_stage(multi, stage_uuid, set: [visible: true])
  end

  project %StageEffortsCleared{} = event, fn multi ->
    %StageEffortsCleared{stage_uuid: stage_uuid} = event

    update_stage(multi, stage_uuid,
      set: [attempt_count: 0, competitor_count: 0, refreshed_at: nil]
    )
  end

  project %StageEffortRecorded{} = event, fn multi ->
    %StageEffortRecorded{stage_uuid: stage_uuid, competitor_count: competitor_count} = event

    update_stage(multi, stage_uuid,
      inc: [attempt_count: 1],
      set: [competitor_count: competitor_count]
    )
  end

  project %StageEffortRemoved{} = event, fn multi ->
    %StageEffortRemoved{stage_uuid: stage_uuid, competitor_count: competitor_count} = event

    update_stage(multi, stage_uuid,
      inc: [attempt_count: -1],
      set: [competitor_count: competitor_count]
    )
  end

  project %StageEffortFlagged{} = event, fn multi ->
    %StageEffortFlagged{stage_uuid: stage_uuid, competitor_count: competitor_count} = event

    update_stage(multi, stage_uuid,
      inc: [attempt_count: -1],
      set: [competitor_count: competitor_count]
    )
  end

  project %CompetitorRemovedFromStage{} = event, fn multi ->
    %CompetitorRemovedFromStage{
      stage_uuid: stage_uuid,
      attempt_count: attempt_count,
      competitor_count: competitor_count
    } = event

    update_stage(multi, stage_uuid,
      inc: [attempt_count: -attempt_count],
      set: [competitor_count: competitor_count]
    )
  end

  project %StageDeleted{} = event, fn multi ->
    %StageDeleted{stage_uuid: stage_uuid} = event

    Ecto.Multi.delete_all(multi, :stage, stage_query(stage_uuid), [])
  end

  project %StageEnded{} = event, fn multi ->
    %StageEnded{stage_uuid: stage_uuid} = event

    update_stage(multi, stage_uuid, set: [status: "past"])
  end

  project %StageLeaderboardsApproved{} = event, fn multi ->
    %StageLeaderboardsApproved{stage_uuid: stage_uuid, approval_message: approval_message} = event

    update_stage(multi, stage_uuid,
      set: [
        approved: true,
        results_markdown: approval_message,
        results_html: markdown_to_html(approval_message)
      ]
    )
  end

  project %StageResultsPublished{} = event, fn multi ->
    %StageResultsPublished{stage_uuid: stage_uuid, message: message} = event

    update_stage(multi, stage_uuid,
      set: [
        approved: true,
        results_markdown: message,
        results_html: markdown_to_html(message)
      ]
    )
  end

  defp update_stage(multi, stage_uuid, updates) do
    Ecto.Multi.update_all(multi, :stage, stage_query(stage_uuid), updates)
  end

  defp stage_query(stage_uuid) do
    from(s in StageProjection,
      where: s.stage_uuid == ^stage_uuid
    )
  end
end
