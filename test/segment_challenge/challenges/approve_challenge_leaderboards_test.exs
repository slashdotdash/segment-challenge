defmodule SegmentChallenge.Challenges.ApproveChallengeLeaderboardsTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase
  import SegmentChallenge.UseCases.ApproveChallengeLeaderboardsUseCase
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase

  alias SegmentChallenge.Events.{
    ChallengeLeaderboardsApproved,
    ChallengeLeaderboardFinalised
  }

  @moduletag :integration

  describe "approve challenge leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :start_stage,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards,
      :end_challenge,
      :approve_challenge_leaderboards
    ]

    test "should confirm approval", context do
      assert_receive_event(
        ChallengeLeaderboardsApproved,
        fn event -> event.challenge_uuid == context[:challenge_uuid] end,
        fn event ->
          assert event.approval_message == "Congratulations to Ben for winning the competition."
          assert event.approved_by_athlete_uuid == context[:athlete_uuid]
          assert event.approved_by_club_uuid == context[:club_uuid]
        end
      )
    end

    test "should finalise challenge leaderboards", %{challenge_uuid: challenge_uuid} do
      assert_receive_event(
        ChallengeLeaderboardFinalised,
        fn event -> event.challenge_uuid == challenge_uuid end,
        fn event ->
          assert event.entries == [
                   %{
                     rank: 1,
                     athlete_uuid: "athlete-5704447",
                     gender: "M",
                     points: 15,
                     distance_in_metres: nil,
                     elapsed_time_in_seconds: nil,
                     elevation_gain_in_metres: nil,
                     goals: nil,
                     moving_time_in_seconds: nil
                   }
                 ]

          assert event.challenge_uuid == challenge_uuid
        end
      )
    end
  end
end
