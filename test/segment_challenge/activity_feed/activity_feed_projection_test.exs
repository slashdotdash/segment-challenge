defmodule SegmentChallenge.Projections.ActivityFeedProjectionTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase
  import SegmentChallenge.UseCases.ApproveChallengeLeaderboardsUseCase
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportAthleteUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase
  import SegmentChallenge.UseCases.ImportClubUseCase

  alias SegmentChallenge.Wait

  alias SegmentChallenge.Events.{
    AthleteAccumulatedPointsInChallengeLeaderboard,
    AthleteImported,
    ChallengeApproved,
    ChallengeCreated,
    ChallengeLeaderboardRanked,
    ChallengeStarted,
    ClubImported,
    CompetitorJoinedChallenge,
    StageLeaderboardFinalised
  }

  alias SegmentChallenge.Repo
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActorProjection

  alias SegmentChallenge.Challenges.Queries.ActivityFeeds.{
    ActivityFeedForActorQuery,
    ActivityFeedForObjectQuery
  }

  @moduletag :integration
  @moduletag :projection

  @athlete_uuid "athlete-5704447"

  describe "athlete joins Segment Challenge" do
    setup [
      :import_athlete
    ]

    test "should create athlete actor" do
      wait_for_event(AthleteImported, fn event -> event.athlete_uuid == @athlete_uuid end)

      assert_actor(
        @athlete_uuid,
        "athlete",
        "Ben Smith",
        "https://example.com/pictures/athletes/large.jpg"
      )
    end
  end

  describe "importing a club" do
    setup [
      :import_club
    ]

    test "should create club actor", context do
      wait_for_event(ClubImported, fn event -> event.club_uuid == context[:club_uuid] end)

      Wait.until(fn ->
        actor = Repo.get(ActorProjection, context[:club_uuid])

        assert actor != nil
        assert actor.actor_type == "club"
        assert actor.actor_name == "VC Venta"

        assert actor.actor_image ==
                 "https://example.com/pictures/clubs/large.jpg"
      end)
    end
  end

  describe "creating a challenge" do
    setup [
      :create_challenge
    ]

    test "should create challenge actor", context do
      wait_for_event(ChallengeCreated, fn event ->
        event.challenge_uuid == context[:challenge_uuid]
      end)

      Wait.until(fn ->
        actor = Repo.get(ActorProjection, context[:challenge_uuid])

        assert actor != nil
        assert actor.actor_type == "challenge"
        assert actor.actor_name == "VC Venta Segment of the Month 2016"
      end)
    end

    test "should create challenge activity", context do
      wait_for_event(ChallengeCreated, fn event ->
        event.challenge_uuid == context[:challenge_uuid]
      end)

      Wait.until(fn ->
        activities =
          ActivityFeedForObjectQuery.new("challenge", context[:challenge_uuid]) |> Repo.all()

        assert length(activities) > 0

        activity = List.last(activities)
        assert activity.message == "Created challenge VC Venta Segment of the Month 2016"
        assert activity.actor_name == "VC Venta"

        assert activity.actor_image ==
                 "https://example.com/pictures/clubs/large.jpg"

        assert activity.object_name == "VC Venta Segment of the Month 2016"
      end)
    end
  end

  describe "hosting a challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge
    ]

    test "should create joined challenge activity when challenge is approved", %{
      challenge_uuid: challenge_uuid
    } do
      wait_for_event(ChallengeApproved, fn event -> event.challenge_uuid == challenge_uuid end)

      Wait.until(fn ->
        activities = ActivityFeedForActorQuery.new("athlete", @athlete_uuid) |> Repo.all()

        assert length(activities) > 0
        assert hd(activities).message == "Joined challenge VC Venta Segment of the Month 2016"
      end)
    end
  end

  describe "competitor joins club and challenge after challenge hosted" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_club,
      :athlete_join_challenge
    ]

    test "should create joined challenge activity" do
      wait_for_event(CompetitorJoinedChallenge, fn event ->
        event.athlete_uuid == @athlete_uuid
      end)

      Wait.until(fn ->
        activities = ActivityFeedForActorQuery.new("athlete", @athlete_uuid) |> Repo.all()

        assert length(activities) > 0
        assert hd(activities).message == "Joined challenge VC Venta Segment of the Month 2016"
      end)
    end
  end

  describe "excluding a competitor from a challenge" do
    setup [
      :create_challenge,
      :athlete_join_challenge,
      :exclude_competitor_from_challenge
    ]

    test "should remove joined challenge activity" do
      Wait.until(fn ->
        activities = ActivityFeedForActorQuery.new("athlete", @athlete_uuid) |> Repo.all()

        assert length(activities) == 0
      end)
    end
  end

  describe "start a challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    test "should create challenge started activity for challenge", %{
      challenge_uuid: challenge_uuid
    } do
      wait_for_event(ChallengeStarted, fn event -> event.challenge_uuid == challenge_uuid end)

      Wait.until(fn ->
        activities = ActivityFeedForActorQuery.new("challenge", challenge_uuid) |> Repo.all()

        assert length(activities) > 0
        assert hd(activities).message == "Stage VCV Sleepers Hill started"
      end)
    end
  end

  describe "rank effort in stage leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :start_stage,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts
    ]

    test "should create stage effort attempt activity", %{stage_uuid: stage_uuid} do
      Wait.until(fn ->
        activity =
          "athlete"
          |> ActivityFeedForActorQuery.new(@athlete_uuid)
          |> Repo.all()
          |> Enum.at(-1)

        assert activity != nil
        assert activity.verb == "attempt"
        assert activity.actor_uuid == @athlete_uuid

        assert activity.actor_image == "https://example.com/pictures/athletes/large.jpg"
        assert activity.message == "Recorded an attempt at stage VCV Sleepers Hill of 3:08"

        assert activity.metadata == %{
                 "activity_type" => "Ride",
                 "athlete_uuid" => "athlete-5704447",
                 "distance_in_metres" => 937.3,
                 "elapsed_time_in_seconds" => 188,
                 "elevation_gain_in_metres" => 68.0,
                 "moving_time_in_seconds" => 188,
                 "stage_name" => "VCV Sleepers Hill",
                 "stage_type" => "mountain",
                 "stage_uuid" => stage_uuid
               }
      end)
    end

    test "should create rank stage effort activity" do
      Wait.until(fn ->
        activity =
          "athlete"
          |> ActivityFeedForActorQuery.new(@athlete_uuid)
          |> Repo.all()
          |> Enum.find(fn activity -> activity.verb == "rank" end)

        assert activity != nil
        assert activity.verb == "rank"
        assert activity.actor_uuid == @athlete_uuid
        assert activity.message == "Ranked 1st in stage VCV Sleepers Hill"
      end)
    end
  end

  describe "approve stage leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :start_stage,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should create final leaderboard position activity" do
      wait_for_event(StageLeaderboardFinalised)

      Wait.until(fn ->
        activity =
          "athlete"
          |> ActivityFeedForActorQuery.new(@athlete_uuid)
          |> Repo.all()
          |> Enum.find(fn activity -> activity.verb == "finish" end)

        assert activity != nil
        assert activity.verb == "finish"
        assert activity.actor_uuid == @athlete_uuid
        assert activity.message == "Finished 1st in stage VCV Sleepers Hill"
      end)
    end

    test "should create accumulated points in challenge leaderboard activity" do
      wait_for_event(AthleteAccumulatedPointsInChallengeLeaderboard, fn event ->
        event.athlete_uuid == @athlete_uuid
      end)

      Wait.until(fn ->
        activities =
          "athlete"
          |> ActivityFeedForActorQuery.new(@athlete_uuid)
          |> Repo.all()
          |> Enum.filter(fn activity -> activity.verb == "accumulate" end)
          |> Enum.sort_by(fn activity -> activity.message end)

        assert activities != []

        Enum.each(activities, fn activity ->
          assert activity.verb == "accumulate"
          assert activity.actor_uuid == @athlete_uuid
        end)

        assert Enum.map(activities, fn activity -> activity.message end) == [
                 "Accumulated 10 points in the KOM leaderboard for VC Venta Segment of the Month 2016",
                 "Accumulated 15 points in the GC leaderboard for VC Venta Segment of the Month 2016"
               ]
      end)
    end

    test "should create ranked in challenge leaderboard activity" do
      wait_for_event(ChallengeLeaderboardRanked)

      Wait.until(fn ->
        activities =
          "athlete"
          |> ActivityFeedForActorQuery.new(@athlete_uuid)
          |> Repo.all()
          |> Enum.filter(fn activity -> activity.verb == "rank" end)
          |> Enum.sort_by(fn activity -> activity.id end)

        assert activities != []

        Enum.each(activities, fn activity ->
          assert activity.verb == "rank"
          assert activity.actor_uuid == @athlete_uuid
        end)

        assert Enum.map(activities, fn activity -> activity.message end) == [
                 "Ranked 1st in stage VCV Sleepers Hill",
                 "Ranked 1st in GC leaderboard",
                 "Ranked 1st in KOM leaderboard"
               ]
      end)
    end
  end

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

    test "should create ranked in challenge leaderboard activity" do
      Wait.until(fn ->
        activities =
          "athlete"
          |> ActivityFeedForActorQuery.new(@athlete_uuid)
          |> Repo.all()
          |> Enum.filter(fn activity -> activity.verb == "finish" end)
          |> Enum.sort_by(fn activity -> activity.message end)

        assert activities != []

        Enum.each(activities, fn activity ->
          assert activity.verb == "finish"
          assert activity.actor_uuid == @athlete_uuid
        end)

        assert Enum.map(activities, fn activity -> activity.message end) == [
                 "Finished 1st in VC Venta Segment of the Month 2016 GC competition",
                 "Finished 1st in VC Venta Segment of the Month 2016 KOM competition",
                 "Finished 1st in stage VCV Sleepers Hill"
               ]
      end)
    end
  end

  describe "delete stage from a challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :delete_stage
    ]

    test "should remove stage actor", %{stage_uuid: stage_uuid} do
      Wait.until(fn ->
        actor = Repo.get(ActorProjection, stage_uuid)

        assert actor == nil
      end)
    end

    test "should remove stage activities", %{stage_uuid: stage_uuid} do
      Wait.until(fn ->
        actor_activities = ActivityFeedForActorQuery.new("stage", stage_uuid) |> Repo.all()
        object_activities = ActivityFeedForObjectQuery.new("stage", stage_uuid) |> Repo.all()

        assert length(actor_activities) == 0
        assert length(object_activities) == 0
      end)
    end
  end

  describe "updating a club profile" do
    setup [
      :create_challenge,
      :import_club_different_profile
    ]

    test "should update actor profile", %{club_uuid: club_uuid} do
      Wait.until(fn ->
        actor = Repo.get(ActorProjection, club_uuid)

        assert actor != nil
        assert actor.actor_type == "club"
        assert actor.actor_name == "VC Venta"

        assert actor.actor_image ==
                 "https://example.com/pictures/clubs/edited.jpg"
      end)
    end

    test "should update profile for actor's activities", %{club_uuid: club_uuid} do
      Wait.until(fn ->
        actor_activities = ActivityFeedForActorQuery.new("club", club_uuid) |> Repo.all()
        object_activities = ActivityFeedForObjectQuery.new("club", club_uuid) |> Repo.all()

        for activity <- actor_activities do
          assert activity.actor_image ==
                   "https://example.com/pictures/clubs/edited.jpg"
        end

        for activity <- object_activities do
          assert activity.object_image ==
                   "https://example.com/pictures/clubs/edited.jpg"
        end
      end)
    end
  end

  defp assert_actor(uuid, type, name, image) do
    Wait.until(fn ->
      actor = Repo.get(ActorProjection, uuid)

      assert actor != nil
      assert actor.actor_type == type
      assert actor.actor_name == name
      assert actor.actor_image == image
    end)
  end
end
