defmodule SegmentChallenge.UseCases.CreateStageUseCase do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use SegmentChallenge.Stages.Stage.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.Factory

  alias SegmentChallenge.Router

  def create_stage(context), do: create_segment_stage(context)

  def create_segment_stage(context) do
    %{challenge_uuid: challenge_uuid, strava_club_id: strava_club_id} = context

    stage_uuid = UUID.uuid4()

    use_cassette "stage/create_segment_stage##{strava_club_id}", match_requests_on: [:query] do
      :ok =
        dispatch(:create_segment_stage,
          stage_uuid: stage_uuid,
          challenge_uuid: challenge_uuid,
          strava_segment_factory: &CreateSegmentStage.Segment.build/1
        )

      wait_for_event(StageSegmentConfigured, fn event -> event.stage_uuid == stage_uuid end)
    end

    [
      stage_uuid: stage_uuid
    ]
  end

  def create_virtual_segment_stage(context) do
    %{challenge_uuid: challenge_uuid, strava_club_id: strava_club_id} = context

    stage_uuid = UUID.uuid4()

    use_cassette "stage/create_virtual_segment_stage##{strava_club_id}",
      match_requests_on: [:query] do
      :ok =
        dispatch(:create_segment_stage,
          stage_uuid: stage_uuid,
          challenge_uuid: challenge_uuid,
          name: "zwift",
          strava_segment_id: 19_141_092,
          strava_segment_factory: &CreateSegmentStage.Segment.build/1
        )

      wait_for_event(StageSegmentConfigured, fn event -> event.stage_uuid == stage_uuid end)
    end

    [
      stage_uuid: stage_uuid
    ]
  end

  def create_distance_stage(context) do
    %{challenge_uuid: challenge_uuid, strava_club_id: strava_club_id} = context

    stage_uuid = UUID.uuid4()

    use_cassette "stage/create_distance_stage##{strava_club_id}", match_requests_on: [:query] do
      :ok =
        dispatch(:create_distance_stage, stage_uuid: stage_uuid, challenge_uuid: challenge_uuid)

      wait_for_event(StageCreated, fn event -> event.stage_uuid == stage_uuid end)
    end

    [
      stage_uuid: stage_uuid
    ]
  end

  def create_distance_stage_with_short_goal(context) do
    %{challenge_uuid: challenge_uuid} = context

    stage_uuid = UUID.uuid4()

    :ok =
      dispatch(:create_distance_stage,
        stage_uuid: stage_uuid,
        challenge_uuid: challenge_uuid,
        goal: 1.0,
        goal_units: "miles"
      )

    [
      stage_uuid: stage_uuid
    ]
  end

  def create_second_stage(context) do
    %{challenge_uuid: challenge_uuid, strava_club_id: strava_club_id} = context

    stage_uuid = UUID.uuid4()

    use_cassette "stage/create_stage##{strava_club_id}", match_requests_on: [:query] do
      :ok =
        dispatch(:create_segment_stage,
          name: "VCV Col de Kingsworthy",
          stage_uuid: stage_uuid,
          challenge_uuid: challenge_uuid,
          stage_number: 2,
          start_date: ~N[2016-02-01 00:00:00],
          start_date_local: ~N[2016-02-01 00:00:00],
          end_date: ~N[2016-02-28 23:59:59],
          end_date_local: ~N[2016-02-28 23:59:59]
        )

      wait_for_event(StageSegmentConfigured, fn event -> event.stage_uuid == stage_uuid end)
    end

    [
      stage_uuid: stage_uuid
    ]
  end

  def create_final_stage(context) do
    %{challenge_uuid: challenge_uuid, strava_club_id: strava_club_id} = context

    stage_uuid = UUID.uuid4()

    use_cassette "stage/create_stage##{strava_club_id}", match_requests_on: [:query] do
      :ok =
        dispatch(:create_segment_stage,
          challenge_uuid: challenge_uuid,
          stage_uuid: stage_uuid,
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-10-31 23:59:59],
          end_date_local: ~N[2016-10-31 23:59:59]
        )
    end

    [stage_uuid: stage_uuid]
  end

  def start_stage(context) do
    :ok = Router.dispatch(%StartStage{stage_uuid: context[:stage_uuid]})

    wait_for_event(StageStarted, fn event -> event.stage_uuid == context[:stage_uuid] end)

    context
  end

  def adjust_stage_duration(context) do
    :ok =
      Router.dispatch(%AdjustStageDuration{
        stage_uuid: context[:stage_uuid],
        start_date: ~N[2016-01-02 00:00:00],
        start_date_local: ~N[2016-01-02 00:00:00],
        end_date: ~N[2016-01-30 23:59:59],
        end_date_local: ~N[2016-01-30 23:59:59]
      })

    wait_for_event(StageDurationAdjusted, fn event -> event.stage_uuid == context[:stage_uuid] end)

    context
  end

  def reveal_stage(context) do
    :ok =
      Router.dispatch(%RevealStage{
        stage_uuid: context[:stage_uuid],
        challenge_uuid: context[:challenge_uuid]
      })

    wait_for_event(StageRevealed, fn event -> event.stage_uuid == context[:stage_uuid] end)

    context
  end

  def end_stage(context) do
    :ok = Router.dispatch(%EndStage{stage_uuid: context[:stage_uuid]})

    wait_for_event(StageEnded, fn event -> event.stage_uuid == context[:stage_uuid] end)

    context
  end

  def publish_stage_results(context) do
    %{athlete_uuid: athlete_uuid, club_uuid: club_uuid, stage_uuid: stage_uuid} = context

    command = %PublishStageResults{
      stage_uuid: stage_uuid,
      published_by_athlete_uuid: athlete_uuid,
      published_by_club_uuid: club_uuid,
      message: "Well done to Ben for winning stage 1."
    }

    Router.dispatch(command)
  end

  def delete_stage(context) do
    do_delete_stage(context)

    :ok
  end

  def delete_last_stage(context) do
    %{stage_uuids: stage_uuids} = context

    last_stage_uuid = Enum.at(stage_uuids, -1)

    do_delete_stage(Map.put(context, :stage_uuid, last_stage_uuid))

    :ok
  end

  def wait_for_stage_competitors(_context) do
    wait_for_event(CompetitorsJoinedStage, fn event ->
      Enum.any?(event.competitors, fn competitor ->
        competitor.athlete_uuid == "athlete-5704447"
      end)
    end)

    :ok
  end

  defp do_delete_stage(context) do
    %{
      athlete_uuid: deleted_by_athlete_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid
    } = context

    command = %DeleteStage{
      stage_uuid: stage_uuid,
      challenge_uuid: challenge_uuid,
      deleted_by_athlete_uuid: deleted_by_athlete_uuid
    }

    :ok = Router.dispatch(command)

    wait_for_event(StageDeleted, fn event -> event.stage_uuid == stage_uuid end)
  end

  defp dispatch(command, attrs) do
    command = build(command, attrs)

    Router.dispatch(command)
  end
end
