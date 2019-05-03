defmodule SegmentChallenge.Challenges.CreateChallengeTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase

  alias SegmentChallenge.Events.ChallengeCreated

  @moduletag :integration

  describe "creating a challenge" do
    setup [
      :create_challenge_with_non_unicode_name
    ]

    test "should be created", %{challenge_uuid: challenge_uuid, club_uuid: club_uuid} do
      assert_receive_event(ChallengeCreated, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.hosted_by_club_uuid == club_uuid
        assert event.name == "Segment ❤️ Challenge"
        assert event.url_slug == "segment-challenge"
      end)
    end
  end

  defp create_challenge_with_non_unicode_name(_context) do
    create_challenge_as(name: "Segment ❤️ Challenge")
  end
end
