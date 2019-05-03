defmodule SegmentChallenge.UseCases.ImportStageEffortUseCase do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use SegmentChallenge.Stages.Stage.Aliases

  import ExUnit.Assertions
  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.Factory

  alias SegmentChallenge.Router
  alias SegmentChallenge.Jobs.ImportStravaActivity
  alias SegmentChallenge.Jobs.RemoveStravaActivity
  alias SegmentChallenge.Tasks.ImportActiveStageEfforts
  alias SegmentChallenge.Stages.StageEffortImporter
  alias SegmentChallenge.Strava.Cache

  def wait_for_competitor_to_join_stage(_context) do
    wait_for_event(CompetitorsJoinedStage, fn event ->
      Enum.any?(event.competitors, &(&1.athlete_uuid == "athlete-5704447"))
    end)

    [athlete_uuid: "athlete-5704447"]
  end

  def import_segment_stage_efforts(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    use_cassette "stage/import_segment_stage_efforts##{strava_club_id}",
      match_requests_on: [:query] do
      StageEffortImporter.execute(stage_uuid,
        start_date_local: ~N[2016-01-25 00:00:00],
        end_date_local: ~N[2016-01-25 23:59:59]
      )
    end
  end

  def import_another_segment_stage_effort(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    # https://www.strava.com/activities/481664864
    use_cassette "stage/import_another_segment_stage_effort##{strava_club_id}",
      match_requests_on: [:query] do
      StageEffortImporter.execute(stage_uuid,
        start_date_local: ~N[2016-01-30 00:00:00],
        end_date_local: ~N[2016-01-30 23:59:59]
      )
    end
  end

  def import_slower_segment_stage_effort(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    # https://www.strava.com/activities/465854738
    use_cassette "stage/import_slower_segment_stage_effort##{strava_club_id}",
      match_requests_on: [:query] do
      StageEffortImporter.execute(stage_uuid,
        start_date_local: ~N[2016-01-08 00:00:00],
        end_date_local: ~N[2016-01-08 23:59:59]
      )
    end
  end

  def import_faster_segment_stage_effort(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    use_cassette "stage/import_faster_segment_stage_effort##{strava_club_id}",
      match_requests_on: [:query] do
      StageEffortImporter.execute(stage_uuid,
        start_date_local: ~N[2016-01-07 00:00:00],
        end_date_local: ~N[2016-01-07 23:59:59]
      )
    end
  end

  def import_distance_stage_efforts(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    wait_for_event(CompetitorsJoinedStage, fn event ->
      Enum.any?(event.competitors, &(&1.athlete_uuid == "athlete-5704447"))
    end)

    use_cassette "stage/import_distance_stage_efforts##{strava_club_id}",
      match_requests_on: [:query] do
      :ok =
        StageEffortImporter.execute(stage_uuid,
          start_date: ~N[2018-10-18 00:00:00],
          end_date: ~N[2018-10-31 23:59:59]
        )
    end

    wait_for_event(StageEffortRecorded, fn event -> event.athlete_uuid == "athlete-5704447" end)

    [athlete_uuid: "athlete-5704447"]
  end

  def import_race_stage_efforts(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    wait_for_event(CompetitorsJoinedStage, fn event ->
      Enum.any?(event.competitors, &(&1.athlete_uuid == "athlete-5704447"))
    end)

    # https://www.strava.com/activities/2029711184
    # https://www.strava.com/activities/2036038630
    # https://www.strava.com/activities/2041519332

    use_cassette "stage/import_race_stage_efforts##{strava_club_id}",
      match_requests_on: [:query] do
      :ok =
        StageEffortImporter.execute(stage_uuid,
          start_date: ~N[2018-12-22 00:00:00],
          end_date: ~N[2018-12-31 23:59:59]
        )
    end

    :ok
  end

  @doc """
  Import one segment stage effort.

    - https://www.strava.com/activities/465157631/segments/11176421917

  """
  def import_one_segment_stage_effort(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    wait_for_event(CompetitorsJoinedStage, fn event ->
      Enum.any?(event.competitors, &(&1.athlete_uuid == "athlete-5704447"))
    end)

    use_cassette "stage/import_one_segment_stage_effort##{strava_club_id}",
      match_requests_on: [:query] do
      StageEffortImporter.execute(stage_uuid,
        start_date_local: ~N[2016-01-07 00:00:00],
        end_date_local: ~N[2016-01-07 23:59:59]
      )
    end

    wait_for_event(StageEffortRecorded, fn
      %StageEffortRecorded{strava_activity_id: 465_157_631} -> true
      %StageEffortRecorded{} -> false
    end)

    [athlete_uuid: "athlete-5704447"]
  end

  @doc """
  Import two segment stage efforts.

    - https://www.strava.com/activities/465157631/segments/11176421917
    - https://www.strava.com/activities/465854738/segments/11191491132

  """
  def import_two_segment_stage_efforts(context) do
    %{stage_uuid: stage_uuid, strava_club_id: strava_club_id} = context

    wait_for_event(CompetitorsJoinedStage, fn event ->
      Enum.any?(event.competitors, &(&1.athlete_uuid == "athlete-5704447"))
    end)

    use_cassette "stage/import_two_segment_stage_efforts##{strava_club_id}",
      match_requests_on: [:query] do
      StageEffortImporter.execute(stage_uuid,
        start_date_local: ~N[2016-01-07 00:00:00],
        end_date_local: ~N[2016-01-08 23:59:59]
      )
    end

    wait_for_event(StageEffortRecorded, fn
      %StageEffortRecorded{strava_activity_id: 465_854_738} -> true
      %StageEffortRecorded{} -> false
    end)

    [athlete_uuid: "athlete-5704447"]
  end

  def import_active_stage_efforts(_context) do
    use_cassette "stage/import_active_stage_efforts", match_requests_on: [:query] do
      ImportActiveStageEfforts.execute()
    end
  end

  def import_active_distance_stage_efforts(_context) do
    use_cassette "stage/import_active_distance_stage_efforts", match_requests_on: [:query] do
      ImportActiveStageEfforts.execute()
    end
  end

  def import_active_race_stage_efforts(_context) do
    use_cassette "stage/import_active_race_stage_efforts", match_requests_on: [:query] do
      ImportActiveStageEfforts.execute()
    end
  end

  def import_strava_activity(strava_activity_id) do
    use_cassette "stage/import_strava_activity##{strava_activity_id}",
      match_requests_on: [:query] do
      :ok =
        ImportStravaActivity.perform(
          strava_activity_id: strava_activity_id,
          strava_athlete_id: 5_704_447
        )
    end

    assert Cache.cached?(strava_activity_id, Strava.DetailedActivity)

    :ok
  end

  def remove_strava_activity(strava_activity_id, now \\ NaiveDateTime.utc_now()) do
    :ok =
      RemoveStravaActivity.perform(
        strava_activity_id: strava_activity_id,
        strava_athlete_id: 5_704_447,
        now: now
      )

    refute Cache.cached?(strava_activity_id, Strava.DetailedActivity)

    :ok
  end

  def flag_stage_effort(context) do
    :ok =
      dispatch(:flag_stage_effort,
        stage_uuid: context[:stage_uuid],
        strava_activity_id: 465_157_631,
        strava_segment_effort_id: 11_176_421_917,
        reason: "Group ride",
        flagged_by_athlete_uuid: "athlete-5704447"
      )

    wait_for_event(StageEffortFlagged, fn event ->
      event.strava_segment_effort_id == 11_176_421_917
    end)

    context
  end

  defp dispatch(command, attrs) do
    command = build(command, attrs)

    Router.dispatch(command)
  end
end
