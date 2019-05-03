defmodule SegmentChallenge.Leaderboards.CreateChallengeLeaderboardTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase

  alias SegmentChallenge.Events.{ChallengeLeaderboardCreated}

  describe "creating and hosting a challenge" do
    setup [
      :create_challenge,
      :host_challenge
    ]

    @tag :integration
    test "should create a general classification leaderboard for men", context do
      assert_receive_event(
        ChallengeLeaderboardCreated,
        fn event -> event.name == "GC" && event.gender == "M" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert event.name == "GC"
          assert event.description == "General classification"
          assert event.gender == "M"
        end
      )
    end

    @tag :integration
    test "should create a general classification leaderboard for women", context do
      assert_receive_event(
        ChallengeLeaderboardCreated,
        fn event -> event.name == "GC" && event.gender == "F" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert event.name == "GC"
          assert event.description == "General classification"
          assert event.gender == "F"
        end
      )
    end

    @tag :integration
    test "should create a KOM leaderboard for men", context do
      assert_receive_event(
        ChallengeLeaderboardCreated,
        fn event -> event.name == "KOM" && event.gender == "M" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert event.name == "KOM"
          assert event.description == "King of the mountains"
          assert event.gender == "M"
        end
      )
    end

    @tag :integration
    test "should create a QOM leaderboard for women", context do
      assert_receive_event(
        ChallengeLeaderboardCreated,
        fn event -> event.name == "QOM" && event.gender == "F" end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert event.name == "QOM"
          assert event.description == "Queen of the mountains"
          assert event.gender == "F"
        end
      )
    end
  end
end
