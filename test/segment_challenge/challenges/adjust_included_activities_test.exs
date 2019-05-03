defmodule SegmentChallenge.Challenges.AdjustIncludedActivitiesTest do
  use SegmentChallenge.StorageCase
  use SegmentChallenge.Challenges.Challenge.Aliases
  use SegmentChallenge.Stages.Stage.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Wait

  @moduletag :integration

  describe "adjust challenge included activities" do
    setup [
      :create_distance_challenge,
      :host_challenge,
      :athlete_join_challenge,
      :start_stage,
      :import_distance_stage_efforts,
      :adjust_challenge_included_activities
    ]

    test "should adjust challenge activities", %{challenge_uuid: challenge_uuid} do
      assert_receive_event(
        ChallengeIncludedActivitiesAdjusted,
        fn event -> event.challenge_uuid == challenge_uuid end,
        fn event ->
          assert event.included_activity_types == ["Run"]
        end
      )
    end

    test "should update challenge projection", %{challenge_uuid: challenge_uuid} do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, challenge_uuid)

        refute challenge == nil
        assert challenge.included_activity_types == ["Run"]
      end)
    end

    test "should adjust included stage activities", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageIncludedActivitiesAdjusted,
        fn event -> event.stage_uuid == stage_uuid end,
        fn event ->
          assert event.included_activity_types == ["Run"]
        end
      )
    end

    test "should remove activities for excluded activity types", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageEffortRemoved,
        fn event -> event.stage_uuid == stage_uuid end
      )
    end

    test "should update stage projection", %{stage_uuid: stage_uuid} do
      Wait.until(fn ->
        stage = Repo.get(StageProjection, stage_uuid)

        refute stage == nil
        assert stage.included_activity_types == ["Run"]
      end)
    end
  end
end
