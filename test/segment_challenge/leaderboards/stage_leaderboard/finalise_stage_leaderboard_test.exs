defmodule SegmentChallenge.Leaderboards.FinaliseStageLeaderboardTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase

  alias SegmentChallenge.Events.{StageLeaderboardFinalised}

  @moduletag :integration

  describe "after a stage ends" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should finalise stage leaderboard rankings", context do
      assert_receive_event(
        StageLeaderboardFinalised,
        fn event -> event.stage_uuid == context[:stage_uuid] && event.gender == "M" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert length(event.entries) == 1
          assert hd(event.entries).rank == 1
        end
      )

      assert_receive_event(
        StageLeaderboardFinalised,
        fn event -> event.stage_uuid == context[:stage_uuid] && event.gender == "F" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert length(event.entries) == 0
        end
      )
    end
  end
end
