defmodule SegmentChallenge.Tasks.StartActiveStageTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Tasks.StartActiveStage

  alias SegmentChallenge.Events.{
    StageStarted
  }

  describe "start inactive stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    @tag :task
    @tag :integration
    test "should start the stage", %{stage_uuid: stage_uuid} do
      StartActiveStage.execute()

      assert_receive_event(
        StageStarted,
        fn event -> event.stage_uuid == stage_uuid end,
        fn event ->
          assert event.stage_number == 1
          assert event.start_date == ~N[2016-01-01 00:00:00]
          assert event.start_date_local == ~N[2016-01-01 00:00:00]
        end
      )
    end
  end

  describe "attempt to start ended stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :start_stage,
      :end_stage
    ]

    @tag :task
    @tag :integration
    test "should not start the stage again", %{stage_uuid: stage_uuid} do
      StartActiveStage.execute(~N[2016-01-31 23:59:59])

      assert_receive_event(
        StageStarted,
        fn event -> event.stage_uuid == stage_uuid end,
        fn event ->
          assert event.start_date == ~N[2016-01-01 00:00:00]
          assert event.start_date_local == ~N[2016-01-01 00:00:00]
        end
      )
    end
  end
end
