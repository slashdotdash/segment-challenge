defmodule SegmentChallenge.Tasks.ApproveStageLeaderboardsTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Tasks.ApproveStageLeaderboards

  alias SegmentChallenge.Events.{
    StageEnded,
    StageLeaderboardsApproved,
    StageStarted
  }

  alias SegmentChallenge.Repo
  alias SegmentChallenge.Wait

  @moduletag :task
  @moduletag :integration

  describe "approve past stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :end_stage
    ]

    test "should approve stage leaderboards for stages ended at least 3 days ago", %{
      challenge_uuid: challenge_uuid,
      club_uuid: club_uuid,
      stage_uuid: stage_uuid
    } do
      wait_for_event(StageEnded, fn event -> event.stage_uuid == stage_uuid end)

      # approve stage leaderboards using UTC date/time three days after stage end date
      ApproveStageLeaderboards.execute(~N[2016-02-04 00:00:00])

      assert_receive_event(
        StageLeaderboardsApproved,
        fn event -> event.stage_uuid == stage_uuid end,
        fn event ->
          assert event.stage_uuid == stage_uuid
          assert event.challenge_uuid == challenge_uuid
          assert event.approved_by_athlete_uuid == "athlete-5704447"
          assert event.approved_by_club_uuid == club_uuid
          assert event.approval_message == nil
        end
      )

      Wait.until(fn ->
        stage = Repo.get(StageProjection, stage_uuid)

        assert stage.approved
      end)
    end

    test "should not approve stage leaderboards for stages ended less than 3 days ago", %{
      stage_uuid: stage_uuid
    } do
      wait_for_event(StageEnded, fn event -> event.stage_uuid == stage_uuid end)

      # approve stage leaderboards using UTC date/time two days after stage end date
      ApproveStageLeaderboards.execute(~N[2016-02-03 00:00:00])

      :timer.sleep(1_000)

      stage = Repo.get(StageProjection, stage_uuid)
      refute stage.approved
    end
  end

  describe "approve active stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    test "should not approve stage leaderboards", %{stage_uuid: stage_uuid} do
      wait_for_event(StageStarted, fn event -> event.stage_uuid == stage_uuid end)

      # approve stage leaderboards using UTC date/time three days after stage end date
      ApproveStageLeaderboards.execute(~N[2016-02-04 00:00:00])

      :timer.sleep(1_000)

      stage = Repo.get(StageProjection, stage_uuid)
      refute stage.approved
    end
  end
end
