defmodule SegmentChallenge.Challenges.CancelChallengeTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Events.{
    ChallengeCancelled,
    StageDeleted
  }

  describe "cancelling a pending challenge" do
    setup [
      :create_challenge,
      :cancel_challenge
    ]

    @tag :integration
    test "should cancel the challenge", %{
      challenge_uuid: challenge_uuid,
      athlete_uuid: athlete_uuid
    } do
      assert_receive_event(ChallengeCancelled, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.cancelled_by_athlete_uuid == athlete_uuid
      end)
    end
  end

  describe "cancelling a pending challenge with stages" do
    setup [
      :create_challenge,
      :create_stage,
      :cancel_challenge
    ]

    @tag :integration
    test "should cancel the challenge", %{
      challenge_uuid: challenge_uuid,
      athlete_uuid: athlete_uuid
    } do
      assert_receive_event(ChallengeCancelled, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.cancelled_by_athlete_uuid == athlete_uuid
      end)
    end

    @tag :integration
    test "should delete the stages", %{challenge_uuid: challenge_uuid} do
      assert_receive_event(StageDeleted, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.stage_number == 1
      end)
    end
  end
end
