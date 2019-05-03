defmodule SegmentChallenge.Projections.Stages.StageProjectionTest do
  use SegmentChallenge.StorageCase

  import SegmentChallenge.Factory
  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Wait
  alias SegmentChallenge.Events.StageEffortRecorded
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Projections.StageProjection

  @moduletag :integration
  @moduletag :projection

  describe "creating a segment challenge containing a segment stage" do
    setup [
      :create_challenge,
      :create_segment_stage
    ]

    test "should create stage projection", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      expected_stage = build(:stage)

      Wait.until(fn ->
        stage = Repo.get(StageProjection, stage_uuid)

        refute is_nil(stage)
        assert stage.stage_number == 1
        assert stage.stage_type == "mountain"
        assert stage.strava_segment_id == 8_622_812
        assert stage.name == expected_stage.name
        assert stage.description_html == "<p>The popular Sleepers Hill. Ouch!</p>\n"
        assert stage.start_date == ~N[2016-01-01 00:00:00]
        assert stage.start_date_local == ~N[2016-01-01 00:00:00]
        assert stage.end_date == ~N[2016-01-31 23:59:59]
        assert stage.end_date_local == ~N[2016-01-31 23:59:59]
        assert stage.included_activity_types == ["Ride"]
        refute stage.allow_private_activities
        assert stage.created_by_athlete_uuid == athlete_uuid
        assert stage.attempt_count == 0
        assert stage.competitor_count == 0
        assert stage.status == "upcoming"
        refute stage.accumulate_activities
        refute stage.visible
      end)
    end

    test "should set Strava segment details", context do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        assert stage.distance_in_metres == 908.2
        assert stage.average_grade == 7.5
        assert stage.maximum_grade == 11.7
        assert stage.start_latitude == 51.056973
        assert stage.start_longitude == -1.327232
        assert stage.end_latitude == 51.058537
        assert stage.end_longitude == -1.339321
        assert stage.map_polyline == "aasvHffbG[hDAp@J`Bh@lDR`Bb@vKC|Bo@rE[hBmA|GeAnF{@pDcAvDc@vA"
      end)
    end
  end

  describe "creating a distance challenge containing a distance stage" do
    setup [
      :create_distance_challenge_with_goal
    ]

    test "should create stage projection", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, stage_uuid)

        refute is_nil(stage)
        assert stage.stage_number == 1
        assert stage.stage_type == "distance"
        assert is_nil(stage.strava_segment_id)
        assert stage.name == "October Cycling Distance Challenge"
        assert stage.description_html == "<p>Can you ride 1,250km in October 2018?</p>\n"
        assert stage.start_date == ~N[2018-10-01 00:00:00]
        assert stage.start_date_local == ~N[2018-10-01 00:00:00]
        assert stage.end_date == ~N[2018-10-31 23:59:59]
        assert stage.end_date_local == ~N[2018-10-31 23:59:59]
        assert stage.included_activity_types == ["Ride"]
        assert stage.allow_private_activities
        assert stage.created_by_athlete_uuid == athlete_uuid
        assert stage.attempt_count == 0
        assert stage.competitor_count == 0
        assert stage.status == "upcoming"
        assert stage.accumulate_activities
        assert stage.visible
      end)
    end

    test "should set stage goal", %{stage_uuid: stage_uuid} do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, stage_uuid)

        refute is_nil(stage)
        assert stage.has_goal
        assert stage.goal == 1_250.0
        assert stage.goal_units == "kilometres"
        assert stage.accumulate_activities
      end)
    end
  end

  describe "hosting a challenge and immediately starting a stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    test "should make stage active", context do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        refute is_nil(stage)
        assert stage.stage_number == 1
        assert stage.status == "active"
        assert stage.visible
      end)
    end
  end

  describe "recording a stage effort" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts
    ]

    test "should record attempt count", context do
      wait_for_event(StageEffortRecorded, fn event -> event.stage_uuid == context[:stage_uuid] end)

      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        refute is_nil(stage)
        assert stage.stage_number == 1
        assert stage.attempt_count == 2
        assert stage.competitor_count == 1
      end)
    end
  end

  describe "adjust a stage duration" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :adjust_stage_duration
    ]

    test "should adjust start/end dates", context do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        refute is_nil(stage)
        assert stage.start_date == ~N[2016-01-02 00:00:00]
        assert stage.start_date_local == ~N[2016-01-02 00:00:00]
        assert stage.end_date == ~N[2016-01-30 23:59:59]
        assert stage.end_date_local == ~N[2016-01-30 23:59:59]
      end)
    end
  end

  describe "revealing a stage" do
    setup [
      :create_challenge,
      :create_stage,
      :reveal_stage
    ]

    test "should make stage visible", context do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        refute is_nil(stage)
        assert stage.visible
      end)
    end
  end

  describe "ending a stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :end_stage
    ]

    test "should make stage inactive", context do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        refute is_nil(stage)
        assert stage.stage_number == 1
        assert stage.status == "past"
      end)
    end
  end

  describe "publish stage results" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :end_stage,
      :publish_stage_results
    ]

    test "should set stage results", context do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        refute is_nil(stage)
        assert stage.results_markdown == "Well done to Ben for winning stage 1."
        assert stage.results_html == "<p>Well done to Ben for winning stage 1.</p>\n"
      end)
    end
  end

  describe "deleting a stage" do
    setup [
      :create_challenge,
      :create_stage,
      :create_second_stage,
      :host_challenge,
      :delete_stage
    ]

    test "should remove stage", context do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, context[:stage_uuid])

        assert is_nil(stage)
      end)
    end
  end
end
