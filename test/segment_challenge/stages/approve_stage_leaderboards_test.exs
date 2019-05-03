defmodule SegmentChallenge.Stages.ApproveStageLeaderboardsTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase

  alias SegmentChallenge.Events.{
    StageLeaderboardsApproved,
    StageLeaderboardFinalised
  }

  describe "approve stage leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    @tag :integration
    test "confirm approval", context do
      assert_receive_event(
        StageLeaderboardsApproved,
        fn event -> event.stage_uuid == context[:stage_uuid] end,
        fn event ->
          assert event.approval_message == "Congratulations to Ben for winning the stage."
        end
      )
    end

    @tag :integration
    test "should finalise stage leaderboards", context do
      assert_receive_event(
        StageLeaderboardFinalised,
        fn event -> event.stage_uuid == context[:stage_uuid] and event.gender == "M" end,
        fn event ->
          assert event.gender == "M"
        end
      )

      assert_receive_event(
        StageLeaderboardFinalised,
        fn event -> event.stage_uuid == context[:stage_uuid] and event.gender == "F" end,
        fn event ->
          assert event.gender == "F"
        end
      )
    end
  end
end
