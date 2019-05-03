defmodule SegmentChallenge.Tasks.StartActiveChallengeTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions

  import SegmentChallenge.UseCases.CreateChallengeUseCase,
    only: [create_future_challenge: 1, host_challenge: 1]

  alias SegmentChallenge.Tasks.StartActiveChallenge

  alias SegmentChallenge.Events.{
    ChallengeStarted
  }

  describe "start upcoming challenge" do
    setup [
      :create_future_challenge,
      :host_challenge
    ]

    @tag :task
    @tag :integration
    test "should start the challenge", %{
      challenge_uuid: challenge_uuid,
      start_date: start_date,
      start_date_local: start_date_local
    } do
      StartActiveChallenge.execute(start_date)

      assert_receive_event(
        ChallengeStarted,
        fn event -> event.challenge_uuid == challenge_uuid end,
        fn event ->
          assert event.start_date == start_date
          assert event.start_date_local == start_date_local
        end
      )
    end
  end
end
