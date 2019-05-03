defmodule SegmentChallenge.Leaderboards.AchieveChallengeLeaderboardGoalTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase

  alias SegmentChallenge.Events.AthleteAchievedChallengeGoal

  @moduletag :integration

  describe "athlete achieve distance challenge leaderboard goal" do
    setup [
      :create_distance_challenge_with_short_goal,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_distance_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should achieve goal", %{challenge_uuid: challenge_uuid} do
      assert_receive_event(AthleteAchievedChallengeGoal, fn event ->
        assert event.challenge_uuid == challenge_uuid
      end)
    end
  end

  describe "athlete achieve distance challenge leaderboard goal after stage removed" do
    setup [
      :create_multi_stage_distance_challenge_with_goal,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_distance_stage_efforts,
      :delete_last_stage,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should achieve goal", %{challenge_uuid: challenge_uuid} do
      assert_receive_event(AthleteAchievedChallengeGoal, fn event ->
        assert event.challenge_uuid == challenge_uuid
      end)
    end
  end

  describe "athlete complete virtual race challenge" do
    setup [
      :create_virtual_race_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_race_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should achieve goal", %{challenge_uuid: challenge_uuid} do
      assert_receive_event(AthleteAchievedChallengeGoal, fn event ->
        assert event.challenge_uuid == challenge_uuid
      end)
    end
  end
end
