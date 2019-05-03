defmodule SegmentChallenge.Stages.Stage.CreateStageTest do
  use SegmentChallenge.StorageCase
  use SegmentChallenge.Stages.Stage.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.Factory
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Router
  alias SegmentChallenge.Commands.ExcludeCompetitorFromChallenge

  alias SegmentChallenge.Events.{
    CompetitorExcludedFromChallenge,
    StageIncludedInChallenge,
    StageRemovedFromChallenge
  }

  @moduletag :integration

  describe "creating a segment stage" do
    setup [
      :create_challenge,
      :create_segment_stage
    ]

    test "should create stage", %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(StageCreated, fn event ->
        assert %StageCreated{
                 challenge_uuid: ^challenge_uuid,
                 stage_uuid: ^stage_uuid,
                 url_slug: "vcv-sleepers-hill"
               } = event
      end)
    end

    test "should include stage in challenge", context do
      assert_receive_event(StageIncludedInChallenge, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
        assert event.stage_uuid == context[:stage_uuid]
        assert event.stage_number == 1
        assert event.name == "VCV Sleepers Hill"
      end)
    end

    test "should configure Strava segment details", %{stage_uuid: stage_uuid} do
      assert_receive_event(StageSegmentConfigured, fn event ->
        %StageSegmentConfigured{
          stage_uuid: ^stage_uuid,
          distance_in_metres: distance_in_metres,
          map_polyline: map_polyline,
          strava_segment_id: strava_segment_id
        } = event

        assert distance_in_metres == 908.2
        assert map_polyline == "aasvHffbG[hDAp@J`Bh@lDR`Bb@vKC|Bo@rE[hBmA|GeAnF{@pDcAvDc@vA"
        assert strava_segment_id == 8_622_812
      end)
    end
  end

  describe "creating a virtual segment stage" do
    setup [
      :create_challenge,
      :create_virtual_segment_stage
    ]

    test "should create stage", %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(StageCreated, fn event ->
        assert %StageCreated{
                 challenge_uuid: ^challenge_uuid,
                 stage_uuid: ^stage_uuid,
                 included_activity_types: ["VirtualRide"],
                 url_slug: "zwift"
               } = event
      end)
    end

    test "should configure Strava segment details", %{stage_uuid: stage_uuid} do
      assert_receive_event(StageSegmentConfigured, fn event ->
        assert %StageSegmentConfigured{
                 stage_uuid: ^stage_uuid,
                 strava_segment_id: 19_141_092,
                 distance_in_metres: 1145.1,
                 map_polyline:
                   "{jywFhhobM[fAqBlEi@`BKt@?\\Ht@\\lBD\\CZKTSPi@XUPOTi@vAY~@SfAEb@?d@Hd@NZf@l@|@r@pAt@|@`@n@PVDX@ZAXGVKRQb@e@p@cAp@sAfAqDpAaF"
               } = event
      end)
    end
  end

  describe "creating a distance challenge without a goal" do
    setup [
      :create_distance_challenge
    ]

    test "should create stage", %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(StageCreated, fn event ->
        assert %StageCreated{
                 challenge_uuid: ^challenge_uuid,
                 stage_uuid: ^stage_uuid,
                 stage_type: "distance",
                 included_activity_types: ["Ride"]
               } = event
      end)
    end

    test "should include stage in challenge", %{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid
    } do
      assert_receive_event(StageIncludedInChallenge, fn event ->
        assert %StageIncludedInChallenge{
                 challenge_uuid: ^challenge_uuid,
                 stage_uuid: ^stage_uuid,
                 stage_number: 1,
                 name: "October Cycling Distance Challenge"
               } = event
      end)
    end
  end

  describe "creating a distance challenge with a goal" do
    setup [
      :create_distance_challenge_with_goal
    ]

    test "should create stage", %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(StageCreated, fn event ->
        assert %StageCreated{
                 challenge_uuid: ^challenge_uuid,
                 stage_uuid: ^stage_uuid,
                 stage_type: "distance",
                 included_activity_types: ["Ride"]
               } = event
      end)
    end

    test "should include stage in challenge", %{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid
    } do
      assert_receive_event(StageIncludedInChallenge, fn event ->
        assert %StageIncludedInChallenge{
                 challenge_uuid: ^challenge_uuid,
                 stage_uuid: ^stage_uuid,
                 stage_number: 1,
                 name: "October Cycling Distance Challenge"
               } = event
      end)
    end

    test "should configure stage goal", %{stage_uuid: stage_uuid} do
      assert_receive_event(StageGoalConfigured, fn event ->
        assert %StageGoalConfigured{
                 stage_uuid: ^stage_uuid,
                 goal: 1_250.0,
                 goal_units: "kilometres"
               } = event
      end)
    end
  end

  describe "creating a duplicate stage" do
    setup [
      :create_challenge,
      :create_segment_stage
    ]

    test "should prevent duplicate stage being created", context do
      stage_uuid = UUID.uuid4()

      response =
        Router.dispatch(
          build(:create_segment_stage,
            challenge_uuid: context[:challenge_uuid],
            stage_uuid: stage_uuid
          )
        )

      assert response ==
               {:error,
                {:validation_failure,
                 [
                   {:error, :stage_number, :by, "duplicate stage number"}
                 ]}}
    end
  end

  describe "starting a stage by starting the challenge" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :host_challenge,
      :athlete_join_challenge
    ]

    test "should start the stage", context do
      assert_receive_event(StageStarted, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
        assert event.stage_uuid == context[:stage_uuid]
        assert event.stage_number == 1
      end)

      assert_receive_event(
        CompetitorsJoinedStage,
        fn event ->
          Enum.any?(event.competitors, fn competitor ->
            competitor.athlete_uuid == "athlete-5704447"
          end)
        end,
        fn event ->
          assert event.stage_uuid == context[:stage_uuid]
          assert length(event.competitors) == 1
        end
      )
    end

    test "should request stage leaderboards", context do
      assert_receive_event(
        StageLeaderboardRequested,
        fn event -> event.stage_uuid == context[:stage_uuid] and event.gender == "M" end,
        fn event ->
          assert event.name == "Men"
        end
      )

      assert_receive_event(
        StageLeaderboardRequested,
        fn event -> event.stage_uuid == context[:stage_uuid] and event.gender == "F" end,
        fn event ->
          assert event.name == "Women"
        end
      )
    end
  end

  describe "excluding a challenge competitor" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :host_challenge,
      :athlete_join_challenge
    ]

    test "should remove competitor", context do
      wait_for_event(CompetitorsJoinedStage, fn event ->
        Enum.any?(event.competitors, fn competitor ->
          competitor.athlete_uuid == "athlete-5704447"
        end)
      end)

      :ok =
        Router.dispatch(%ExcludeCompetitorFromChallenge{
          challenge_uuid: context[:challenge_uuid],
          athlete_uuid: context[:athlete_uuid],
          reason: "not a first claim club member",
          excluded_at: utc_now()
        })

      assert_receive_event(
        CompetitorExcludedFromChallenge,
        fn event -> event.athlete_uuid == context[:athlete_uuid] end,
        fn event ->
          assert event.challenge_uuid == context[:challenge_uuid]
          assert event.reason == "not a first claim club member"
        end
      )

      assert_receive_event(
        CompetitorRemovedFromStage,
        fn event -> event.athlete_uuid == context[:athlete_uuid] end,
        fn event ->
          assert event.stage_uuid == context[:stage_uuid]
        end
      )
    end
  end

  describe "deleting a stage" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :delete_stage
    ]

    test "should delete stage", context do
      assert_receive_event(StageDeleted, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
        assert event.stage_uuid == context[:stage_uuid]
        assert event.stage_number == 1
      end)
    end

    test "should remove stage from challenge", context do
      assert_receive_event(StageRemovedFromChallenge, fn event ->
        assert event.challenge_uuid == context[:challenge_uuid]
        assert event.stage_uuid == context[:stage_uuid]
        assert event.stage_number == 1
      end)
    end
  end

  describe "deleting a second stage" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :create_second_stage,
      :delete_stage
    ]

    test "should delete stage", %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(StageDeleted, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.stage_uuid == stage_uuid
        assert event.stage_number == 2
      end)
    end

    test "should remove stage from challenge", %{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid
    } do
      assert_receive_event(StageRemovedFromChallenge, fn event ->
        assert event.challenge_uuid == challenge_uuid
        assert event.stage_uuid == stage_uuid
        assert event.stage_number == 2
      end)
    end
  end

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()
end
