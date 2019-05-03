defmodule SegmentChallenge.Challenges.HostChallengeTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Events.{
    CompetitorJoinedChallenge,
    CompetitorsJoinedStage,
    CompetitorLeftChallenge,
    CompetitorRemovedFromStage,
    ChallengeLeaderboardRequested,
    ChallengeApproved
  }

  describe "athlete joins a challenge" do
    setup [
      :create_challenge,
      :athlete_join_challenge
    ]

    @tag :integration
    test "should be included as challenge competitor", context do
      assert_receive_event(CompetitorJoinedChallenge, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
        assert event.athlete_uuid == "athlete-5704447"
      end)
    end
  end

  describe "athlete joins after challenge has started" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge
    ]

    @tag :integration
    test "should include athlete as a competitor in challenge", context do
      assert_receive_event(CompetitorJoinedChallenge, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
        assert event.athlete_uuid == "athlete-5704447"
      end)
    end

    @tag :integration
    test "should include athlete as a competitor in active stage", context do
      assert_receive_event(
        CompetitorsJoinedStage,
        fn event ->
          Enum.any?(event.competitors, fn competitor ->
            competitor.athlete_uuid == "athlete-5704447"
          end)
        end,
        fn event ->
          assert event.stage_uuid == context[:stage_uuid]
          assert length(event.competitors) == 1
        end
      )
    end
  end

  describe "athlete leaves challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :athlete_leave_challenge
    ]

    @tag :integration
    test "should remove athlete from challenge", context do
      assert_receive_event(
        CompetitorLeftChallenge,
        fn event -> event.athlete_uuid == context[:athlete_uuid] end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
        end
      )
    end
  end

  describe "athlete leaves challenge after challenge has started" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :athlete_leave_challenge
    ]

    @tag :integration
    test "should remove athlete from active stage", context do
      assert_receive_event(
        CompetitorRemovedFromStage,
        fn event -> event.athlete_uuid == context[:athlete_uuid] end,
        fn event ->
          assert event.stage_uuid == context[:stage_uuid]
        end
      )
    end
  end

  describe "hosting a challenge" do
    setup [
      :create_challenge,
      :host_challenge
    ]

    @tag :integration
    test "should request challenge leaderboards to be created", context do
      assert_receive_event(ChallengeLeaderboardRequested, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
      end)
    end

    @tag :integration
    test "should approve challenge", context do
      assert_receive_event(ChallengeApproved, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
        assert event.approved_by_athlete_uuid == context[:athlete_uuid]
      end)
    end
  end
end
