defmodule SegmentChallenge.Challenges.CreateActivityChallengeTest do
  use SegmentChallenge.StorageCase
  use SegmentChallenge.Challenges.Challenge.Aliases
  use SegmentChallenge.Stages.Stage.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase

  @moduletag :integration

  describe "creating an activity challenge" do
    setup [
      :create_distance_challenge
    ]

    test "should be created", %{challenge_uuid: challenge_uuid, club_uuid: club_uuid} do
      assert_receive_event(ChallengeCreated, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.challenge_type == "distance"
        assert event.hosted_by_club_uuid == club_uuid
        assert event.url_slug == "october-cycling-distance-challenge"
      end)
    end

    test "should create activity stage", %{challenge_uuid: challenge_uuid} do
      assert_receive_event(StageCreated, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.stage_type == "distance"
        assert event.visible?
      end)
    end
  end
end
