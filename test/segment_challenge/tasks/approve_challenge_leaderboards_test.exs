defmodule SegmentChallenge.Tasks.ApproveChallengeLeaderboardsTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Tasks.ApproveChallengeLeaderboards

  alias SegmentChallenge.Events.{
    ChallengeEnded,
    ChallengeLeaderboardsApproved,
    ChallengeStarted
  }

  alias SegmentChallenge.Repo
  alias SegmentChallenge.Wait

  @moduletag :task
  @moduletag :integration

  describe "approve past challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :end_stage,
      :end_challenge,
      :approve_stage_leaderboards
    ]

    test "should approve challenge leaderboards for challenge ended at least 3 days ago", %{
      challenge_uuid: challenge_uuid,
      club_uuid: club_uuid
    } do
      wait_for_event(ChallengeEnded, fn event -> event.challenge_uuid == challenge_uuid end)

      # Approve challenge leaderboards using UTC date/time three days after challenge end date.
      ApproveChallengeLeaderboards.execute(~N[2016-11-04 00:00:00])

      assert_receive_event(
        ChallengeLeaderboardsApproved,
        fn event -> event.challenge_uuid == challenge_uuid end,
        fn event ->
          assert event.challenge_uuid == challenge_uuid
          assert event.approved_by_athlete_uuid == "athlete-5704447"
          assert event.approved_by_club_uuid == club_uuid
          assert event.approval_message == nil
        end
      )

      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, challenge_uuid)

        refute is_nil(challenge)
        assert challenge.approved
      end)
    end

    test "should not approve challenge leaderboards for challenges ended less than 3 days ago", %{
      challenge_uuid: challenge_uuid
    } do
      wait_for_event(ChallengeEnded, fn event -> event.challenge_uuid == challenge_uuid end)

      # Approve stage leaderboards using UTC date/time two days after stage end date
      ApproveChallengeLeaderboards.execute(~N[2016-11-03 00:00:00])

      :timer.sleep(1_000)

      challenge = Repo.get(ChallengeProjection, challenge_uuid)
      refute challenge.approved
    end
  end

  describe "approve active challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    test "should not approve challenge leaderboards", %{challenge_uuid: challenge_uuid} do
      wait_for_event(ChallengeStarted, fn event -> event.challenge_uuid == challenge_uuid end)

      # approve challenge leaderboards using UTC date/time three days after challenge end date
      ApproveChallengeLeaderboards.execute(~N[2016-11-04 00:00:00])

      :timer.sleep(1_000)

      challenge = Repo.get(ChallengeProjection, challenge_uuid)
      refute challenge.approved
    end
  end
end
