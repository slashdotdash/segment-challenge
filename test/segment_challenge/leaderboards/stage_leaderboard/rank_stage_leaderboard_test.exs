defmodule SegmentChallenge.Leaderboards.RankStageLeaderboardTest do
  use SegmentChallenge.StorageCase
  use SegmentChallenge.Leaderboards.StageLeaderboard.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  @moduletag :integration

  describe "rank stage leaderboard for segment stage efforts" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts
    ]

    test "should be ranked in stage leaderboard", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageLeaderboardRanked,
        fn event ->
          # https://www.strava.com/activities/478127401/segments/11478431697
          assert %StageLeaderboardRanked{
                   stage_uuid: ^stage_uuid,
                   has_goal?: false,
                   stage_efforts: [
                     %StageLeaderboardRanked.StageEffort{
                       athlete_uuid: "athlete-5704447",
                       athlete_gender: "M",
                       strava_activity_id: 478_127_401,
                       strava_segment_effort_id: 11_478_431_697,
                       activity_type: "Ride",
                       elapsed_time_in_seconds: 188,
                       moving_time_in_seconds: 188,
                       start_date: ~N[2016-01-25 12:48:14],
                       start_date_local: ~N[2016-01-25 12:48:14],
                       distance_in_metres: 937.3,
                       elevation_gain_in_metres: 68.0,
                       average_cadence: 94.3,
                       average_heartrate: nil,
                       average_watts: 352.0,
                       device_watts?: true,
                       max_heartrate: nil,
                       goal_progress: nil,
                       private?: false,
                       stage_effort_count: 1
                     }
                   ],
                   new_positions: [
                     %StageLeaderboardRanked.Ranking{
                       rank: 1,
                       athlete_uuid: "athlete-5704447"
                     }
                   ],
                   positions_gained: [],
                   positions_lost: []
                 } = event
        end
      )
    end
  end

  describe "rank stage leaderboard after a faster segment stage effort" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_slower_segment_stage_effort,
      :import_faster_segment_stage_effort
    ]

    test "should rank faster effort in stage leaderboard", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageLeaderboardRanked,
        fn event ->
          Enum.any?(event.stage_efforts, fn stage_effort ->
            stage_effort.stage_effort_count == 2
          end)
        end,
        fn event ->
          assert_faster_segment_effort_ranked(stage_uuid, event)
        end
      )
    end
  end

  describe "rank stage leaderboard after a slower segment stage effort" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_faster_segment_stage_effort,
      :import_slower_segment_stage_effort
    ]

    test "should not rank slower effort in stage leaderboard", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageLeaderboardRanked,
        fn event ->
          Enum.any?(event.stage_efforts, fn stage_effort ->
            stage_effort.stage_effort_count == 2
          end)
        end,
        fn event ->
          assert_faster_segment_effort_ranked(stage_uuid, event)
        end
      )
    end
  end

  defp assert_faster_segment_effort_ranked(stage_uuid, %StageLeaderboardRanked{} = event) do
    assert %StageLeaderboardRanked{
             stage_uuid: ^stage_uuid,
             stage_efforts: [%StageLeaderboardRanked.StageEffort{} = stage_effort],
             new_positions: [],
             positions_gained: [],
             positions_lost: []
           } = event

    # https://www.strava.com/activities/465157631/segments/11176421917
    assert stage_effort.strava_activity_id == 465_157_631
    assert stage_effort.strava_segment_effort_id == 11_176_421_917
  end

  describe "rank stage leaderboard for distance stage efforts" do
    setup [
      :create_distance_challenge_with_goal,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_distance_stage_efforts
    ]

    test "should be ranked in stage leaderboard", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageLeaderboardRanked,
        fn
          %StageLeaderboardRanked{
            stage_efforts: [%StageLeaderboardRanked.StageEffort{stage_effort_count: 3}]
          } ->
            true

          %StageLeaderboardRanked{} ->
            false
        end,
        fn event ->
          assert %StageLeaderboardRanked{
                   stage_uuid: ^stage_uuid,
                   has_goal?: true,
                   stage_efforts: [stage_effort],
                   new_positions: [],
                   positions_gained: [],
                   positions_lost: []
                 } = event

          assert %StageLeaderboardRanked.StageEffort{
                   athlete_uuid: "athlete-5704447",
                   athlete_gender: "M",
                   strava_activity_id: 1_936_443_168,
                   strava_segment_effort_id: nil,
                   activity_type: "Ride",
                   elapsed_time_in_seconds: 18363,
                   moving_time_in_seconds: 16531,
                   start_date: ~N[2018-10-30 18:51:34],
                   start_date_local: ~N[2018-10-30 18:51:34],
                   distance_in_metres: 145_129.8,
                   elevation_gain_in_metres: 1421.0,
                   average_cadence: nil,
                   average_heartrate: nil,
                   average_watts: 194.63333333333335,
                   device_watts?: true,
                   max_heartrate: nil,
                   private?: false,
                   stage_effort_count: 3,
                   goal_progress: goal_progress
                 } = stage_effort

          assert Decimal.equal?(goal_progress, Decimal.from_float(11.61038400))
        end
      )
    end
  end
end
