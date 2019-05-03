defmodule SegmentChallenge.Tasks.EndPastChallengeTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase

  alias SegmentChallenge.Tasks.EndPastChallenge
  alias SegmentChallenge.Events.{ChallengeEnded}
  alias SegmentChallenge.Infrastructure.DateTime.Now

  setup do
    on_exit(fn ->
      Now.reset()
    end)

    :ok
  end

  describe "end past challenge" do
    setup [
      :create_challenge,
      :host_challenge
    ]

    @tag :task
    @tag :integration
    test "should end the challenge", context do
      # set current UTC date/time to after challenge end date
      Now.set(~N[2016-11-01 00:00:00])

      EndPastChallenge.execute()

      assert_receive_event(
        ChallengeEnded,
        fn event -> event.challenge_uuid == context[:challenge_uuid] end,
        fn event ->
          assert event.end_date == ~N[2016-10-31 23:59:59]
          assert event.end_date_local == ~N[2016-10-31 23:59:59]
        end
      )
    end
  end
end
