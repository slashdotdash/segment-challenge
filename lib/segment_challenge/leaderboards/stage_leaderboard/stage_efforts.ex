defmodule SegmentChallenge.Leaderboards.StageLeaderboard.StageEfforts do
  alias SegmentChallenge.Events.CompetitorRemovedFromStage
  alias SegmentChallenge.Events.StageEffortFlagged
  alias SegmentChallenge.Events.StageEffortRecorded
  alias SegmentChallenge.Events.StageEffortRemoved
  alias SegmentChallenge.Events.StageEffortsCleared

  def accumulate_stage_effort(_stage_efforts, %StageEffortsCleared{}), do: []

  def accumulate_stage_effort(stage_efforts, %StageEffortRecorded{} = event) do
    %StageEffortRecorded{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = event

    unless existing_effort?(stage_efforts, strava_activity_id, strava_segment_effort_id) do
      [event | stage_efforts]
    else
      stage_efforts
    end
  end

  def accumulate_stage_effort(stage_efforts, %StageEffortFlagged{} = event) do
    %StageEffortFlagged{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = event

    remove_stage_effort(stage_efforts, strava_activity_id, strava_segment_effort_id)
  end

  def accumulate_stage_effort(stage_efforts, %StageEffortRemoved{} = event) do
    %StageEffortRemoved{
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id
    } = event

    remove_stage_effort(stage_efforts, strava_activity_id, strava_segment_effort_id)
  end

  def accumulate_stage_effort(stage_efforts, %CompetitorRemovedFromStage{} = event) do
    %CompetitorRemovedFromStage{athlete_uuid: athlete_uuid} = event

    Enum.reject(stage_efforts, fn
      %StageEffortRecorded{athlete_uuid: ^athlete_uuid} -> true
      %StageEffortRecorded{} -> false
    end)
  end

  def accumulate_stage_effort(stage_efforts, _event), do: stage_efforts

  defp existing_effort?(stage_efforts, strava_activity_id, strava_segment_effort_id) do
    Enum.any?(stage_efforts, fn
      %StageEffortRecorded{
        strava_activity_id: ^strava_activity_id,
        strava_segment_effort_id: ^strava_segment_effort_id
      } ->
        true

      %StageEffortRecorded{} ->
        false
    end)
  end

  defp remove_stage_effort(stage_efforts, strava_activity_id, strava_segment_effort_id) do
    Enum.reject(stage_efforts, fn
      %StageEffortRecorded{
        strava_activity_id: ^strava_activity_id,
        strava_segment_effort_id: ^strava_segment_effort_id
      } ->
        true

      %StageEffortRecorded{} ->
        false
    end)
  end
end
