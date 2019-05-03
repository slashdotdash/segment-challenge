defmodule SegmentChallenge.Leaderboards.HistoricalStageLeaderboardTest do
  use SegmentChallenge.AggregateCase, aggregate: SegmentChallenge.Leaderboards.StageLeaderboard

  @moduletag :unit

  describe "finalise historical stage leaderboard" do
    test "should create final entries" do
      assert_events(
        stage_leaderboard_created_with_two_athlete_ranked_efforts(),
        [
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1",
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             ),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete2",
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165
             )
           ]},
          :finalise_stage_leaderboard
        ],
        [
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete2",
               rank: 1,
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165
             ),
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               rank: 2,
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ],
           new_positions: []},
          {:stage_leaderboard_finalised,
           entries: [
             %{
               rank: 1,
               athlete_uuid: "athlete2",
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               distance_in_metres: 937.3,
               elevation_gain_in_metres: 68.0,
               stage_effort_count: 1
             },
             %{
               rank: 2,
               athlete_uuid: "athlete1",
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172,
               distance_in_metres: 937.3,
               elevation_gain_in_metres: 68.0,
               stage_effort_count: 1
             }
           ]}
        ]
      )
    end

    test "should handle remove stage effort" do
      assert_events(
        stage_leaderboard_created_with_removed_stage_effort(),
        [
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1",
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ]},
          :finalise_stage_leaderboard
        ],
        [
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               rank: 1,
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ],
           new_positions: []},
          {:stage_leaderboard_finalised,
           entries: [
             %{
               rank: 1,
               athlete_uuid: "athlete1",
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172,
               distance_in_metres: 937.3,
               elevation_gain_in_metres: 68.0,
               stage_effort_count: 1
             }
           ]}
        ]
      )
    end
  end

  defp stage_leaderboard_created_with_two_athlete_ranked_efforts do
    [
      :stage_leaderboard_created,
      {:athlete_ranked_in_stage_leaderboard,
       rank: 1,
       athlete_uuid: "athlete1",
       strava_activity_id: 1,
       strava_segment_effort_id: 1,
       elapsed_time_in_seconds: 172,
       moving_time_in_seconds: 172},
      {:athlete_ranked_in_stage_leaderboard,
       rank: 1,
       athlete_uuid: "athlete2",
       strava_activity_id: 2,
       strava_segment_effort_id: 2,
       elapsed_time_in_seconds: 165,
       moving_time_in_seconds: 165},
      {:stage_leaderboard_ranked,
       stage_efforts: nil,
       positions_lost: [build(:stage_leaderboard_ranking, rank: 2, athlete_uuid: "athlete1")]}
    ]
  end

  defp stage_leaderboard_created_with_removed_stage_effort do
    [
      stage_leaderboard_created_with_two_athlete_ranked_efforts(),
      {:stage_effort_removed_from_stage_leaderboard,
       rank: 1, athlete_uuid: "athlete2", strava_activity_id: 2, strava_segment_effort_id: 2},
      {:stage_leaderboard_ranked,
       stage_efforts: nil,
       positions_lost: [],
       positions_gained: [build(:stage_leaderboard_ranking, rank: 1, athlete_uuid: "athlete1")]}
    ]
  end
end
