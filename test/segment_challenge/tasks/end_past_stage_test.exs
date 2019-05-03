defmodule SegmentChallenge.Tasks.EndPastStageTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Tasks.EndPastStage

  alias SegmentChallenge.Events.{
    StageEnded,
    StageStarted
  }

  alias SegmentChallenge.Infrastructure.DateTime.Now

  @moduletag :task
  @moduletag :integration

  setup do
    on_exit(fn ->
      Now.reset()
    end)

    :ok
  end

  describe "end past stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    test "should end the stage", %{stage_uuid: stage_uuid} do
      wait_for_event(StageStarted, fn event -> event.stage_uuid == stage_uuid end)

      # set current UTC date/time to after stage end date
      Now.set(~N[2016-02-01 00:00:00])

      EndPastStage.execute()

      assert_receive_event(StageEnded, fn event -> event.stage_uuid == stage_uuid end, fn event ->
        assert event.end_date == ~N[2016-01-31 23:59:59]
        assert event.end_date_local == ~N[2016-01-31 23:59:59]
      end)
    end
  end
end
