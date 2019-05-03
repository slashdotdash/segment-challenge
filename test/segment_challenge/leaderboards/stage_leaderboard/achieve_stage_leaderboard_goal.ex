defmodule SegmentChallenge.Leaderboards.AchieveStageLeaderboardTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Events.AthleteAchievedStageGoal

  @moduletag :integration

  describe "athlete achieve activity stage goal" do
    setup [
      :create_distance_challenge_with_short_goal,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_distance_stage_efforts
    ]

    test "should achieve goal", %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(AthleteAchievedStageGoal, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.stage_uuid == stage_uuid
      end)
    end
  end

  describe "athlete complete virtual race" do
    setup [
      :create_virtual_race_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_race_stage_efforts
    ]

    test "should achieve goal", %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(AthleteAchievedStageGoal, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.stage_uuid == stage_uuid
      end)
    end
  end
end
