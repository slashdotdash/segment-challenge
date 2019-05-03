defmodule SegmentChallenge.Stages.Stage.FlagStageEffortTest do
  use SegmentChallenge.StorageCase
  use SegmentChallenge.Stages.Stage.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Events.StageLeaderboardRanked

  @moduletag :integration

  describe "flag athlete's only stage effort" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :second_athlete_join_challenge,
      :import_one_segment_stage_effort,
      :flag_stage_effort
    ]

    test "should flag effort" do
      assert_receive_event(
        StageEffortFlagged,
        fn event -> event.strava_segment_effort_id == 11_176_421_917 end,
        fn event ->
          assert event.athlete_uuid == "athlete-5704447"
          assert event.flagged_by_athlete_uuid == "athlete-5704447"
          assert event.reason == "Group ride"
          assert event.attempt_count == 0
          assert event.competitor_count == 0
        end
      )
    end

    test "should remove stage effort from leaderboard" do
      assert_receive_event(
        StageLeaderboardRanked,
        fn event -> event.stage_efforts == [] end,
        fn event ->
          assert event.stage_efforts == []
        end
      )
    end
  end

  describe "flag athlete's faster stage effort" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :second_athlete_join_challenge,
      :import_two_segment_stage_efforts,
      :flag_stage_effort
    ]

    test "should flag effort" do
      assert_receive_event(
        StageEffortFlagged,
        fn event -> event.strava_segment_effort_id == 11_176_421_917 end,
        fn event ->
          assert event.athlete_uuid == "athlete-5704447"
          assert event.flagged_by_athlete_uuid == "athlete-5704447"
          assert event.reason == "Group ride"
          assert event.attempt_count == 1
          assert event.competitor_count == 1
        end
      )
    end

    test "should remove stage effort from leaderboard and replace with slower attempt" do
      assert_receive_event(
        StageLeaderboardRanked,
        fn event ->
          event.stage_efforts
          |> Enum.reject(fn stage_effort ->
            stage_effort.strava_segment_effort_id == 11_176_421_917
          end)
          |> Enum.any?()
        end,
        fn event ->
          stage_effort = hd(event.stage_efforts)

          assert stage_effort.athlete_uuid == "athlete-5704447"
          assert stage_effort.rank == 1
          assert stage_effort.strava_activity_id == 465_854_738
          assert stage_effort.strava_segment_effort_id == 11_191_491_132
          assert stage_effort.elapsed_time_in_seconds == 218
          assert stage_effort.moving_time_in_seconds == 218
          assert stage_effort.distance_in_metres == 954.6
          assert stage_effort.elevation_gain_in_metres == 68.0
          assert stage_effort.start_date == ~N[2016-01-08 17:57:41]
          assert stage_effort.start_date_local == ~N[2016-01-08 17:57:41]
          assert stage_effort.average_cadence == 84.1
          assert stage_effort.average_watts == 313.2
        end
      )
    end
  end
end
