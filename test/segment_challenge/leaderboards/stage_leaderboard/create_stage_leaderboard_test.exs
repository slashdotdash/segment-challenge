defmodule SegmentChallenge.Leaderboards.CreateStageLeaderboardTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Events.{StageLeaderboardCreated}

  describe "creating a challenge and starting a stage" do
    setup [
      :create_challenge,
      :create_stage,
      :start_stage
    ]

    @tag :integration
    test "should create a stage leaderboard for men", context do
      assert_receive_event(
        StageLeaderboardCreated,
        fn event -> event.gender == "M" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert event.stage_uuid == context[:stage_uuid]
          assert event.gender == "M"
          assert event.name == "Men"
        end
      )
    end

    @tag :integration
    test "should create a stage leaderboard for women", context do
      assert_receive_event(
        StageLeaderboardCreated,
        fn event -> event.gender == "F" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert event.stage_uuid == context[:stage_uuid]
          assert event.gender == "F"
          assert event.name == "Women"
        end
      )
    end
  end
end
