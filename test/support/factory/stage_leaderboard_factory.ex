defmodule SegmentChallenge.StageLeaderboardFactory do
  use SegmentChallenge.Leaderboards.StageLeaderboard.Aliases

  defmacro __using__(_opts) do
    quote do
      @stage_leaderboard_uuid UUID.uuid4()
      @challenge_uuid UUID.uuid4()
      @stage_uuid UUID.uuid4()

      def create_stage_leaderboard_factory do
        %CreateStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_type: "mountain",
          name: "Men",
          gender: "M",
          rank_by: "elapsed_time_in_seconds",
          rank_order: "asc",
          accumulate_activities: false,
          has_goal: false
        }
      end

      def create_distance_stage_leaderboard_factory do
        build(:create_stage_leaderboard,
          rank_by: "distance_in_metres",
          rank_order: "desc",
          accumulate_activities: true,
          has_goal: false
        )
      end

      def create_distance_stage_leaderboard_with_goal_factory do
        build(:create_stage_leaderboard,
          rank_by: "distance_in_metres",
          rank_order: "desc",
          accumulate_activities: true,
          has_goal: true,
          goal: 1.0,
          goal_units: "miles"
        )
      end

      def stage_leaderboard_created_factory do
        %StageLeaderboardCreated{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_type: "mountain",
          name: "Men",
          gender: "M",
          rank_by: "elapsed_time_in_seconds",
          rank_order: "asc",
          accumulate_activities?: false,
          has_goal?: false
        }
      end

      def rank_stage_efforts_in_stage_leaderboard_factory do
        %RankStageEffortsInStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          stage_efforts: [
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort)
          ]
        }
      end

      def rank_stage_efforts_in_stage_leaderboard_stage_effort_factory do
        %RankStageEffortsInStageLeaderboard.StageEffort{
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
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          private?: false
        }
      end

      def stage_leaderboard_ranked_factory do
        %StageLeaderboardRanked{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          stage_uuid: @stage_uuid,
          challenge_uuid: @challenge_uuid,
          stage_efforts: [
            build(:stage_leaderboard_ranked_stage_effort)
          ],
          new_positions: [
            %StageLeaderboardRanked.Ranking{
              athlete_uuid: "athlete-5704447",
              rank: 1,
              positions_changed: nil
            }
          ],
          positions_gained: [],
          positions_lost: [],
          has_goal?: false
        }
      end

      def stage_leaderboard_ranking_factory do
        %StageLeaderboardRanked.Ranking{
          athlete_uuid: "athlete-5704447",
          rank: 2,
          positions_changed: 1
        }
      end

      def stage_leaderboard_ranked_stage_effort_factory do
        %StageLeaderboardRanked.StageEffort{
          rank: 1,
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
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          goal_progress: nil,
          stage_effort_count: 1,
          private?: false
        }
      end

      def rank_effort_in_stage_leaderboard_factory do
        %RankStageEffortInStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
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
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          private?: false
        }
      end

      def athlete_ranked_in_stage_leaderboard_factory do
        %AthleteRankedInStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          rank: 1,
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
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          private?: false,
          stage_effort_count: 1,
          goal_progress: nil
        }
      end

      def athlete_recorded_improved_stage_effort_factory do
        %AthleteRecordedImprovedStageEffort{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          rank: 1,
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
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          private?: false,
          stage_effort_count: 1
        }
      end

      def athlete_recorded_worse_stage_effort_factory do
        %AthleteRecordedWorseStageEffort{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
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
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          private?: false,
          stage_effort_count: 1
        }
      end

      def pending_adjustment_in_stage_leaderboard_factory do
        %PendingAdjustmentInStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
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
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          private?: false
        }
      end

      def athlete_achieved_stage_goal_factory do
        %AthleteAchievedStageGoal{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          athlete_uuid: "athlete-5704447",
          strava_activity_id: 478_127_401,
          strava_segment_effort_id: 11_478_431_697,
          goal: 1_000.0,
          goal_units: "miles",
          single_activity_goal?: false
        }
      end

      def remove_competitor_from_stage_leaderboard_factory do
        %RemoveCompetitorFromStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          athlete_uuid: "athlete-5704447"
        }
      end

      def remove_stage_effort_from_stage_leaderboard_factory do
        %RemoveStageEffortFromStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          athlete_uuid: "athlete-5704447",
          strava_activity_id: 478_127_401,
          strava_segment_effort_id: 11_478_431_697,
          reason: "Group ride",
          removed_at: ~N[2016-01-26 12:01:00]
        }
      end

      def stage_effort_removed_from_stage_leaderboard_factory do
        %StageEffortRemovedFromStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          rank: 1,
          athlete_uuid: "athlete-5704447",
          strava_activity_id: 478_127_401,
          strava_segment_effort_id: 11_478_431_697,
          reason: "Group ride",
          replaced_by: nil
        }
      end

      def stage_effort_removed_from_stage_leaderboard_replacement_factory do
        %StageEffortRemovedFromStageLeaderboard.StageEffort{
          strava_activity_id: 478_127_401,
          strava_segment_effort_id: 11_478_431_697,
          activity_type: "Ride",
          elapsed_time_in_seconds: 188,
          moving_time_in_seconds: 188,
          distance_in_metres: 937.3,
          elevation_gain_in_metres: 68.0,
          start_date: ~N[2016-01-25 12:48:14],
          start_date_local: ~N[2016-01-25 12:48:14],
          average_cadence: 94.3,
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          private?: false,
          stage_effort_count: 1
        }
      end

      def athlete_removed_from_stage_leaderboard_factory do
        %AthleteRemovedFromStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          athlete_uuid: "athlete-5704447",
          rank: 1
        }
      end

      def finalise_stage_leaderboard_factory do
        %FinaliseStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid
        }
      end

      def stage_leaderboard_finalised_factory do
        %StageLeaderboardFinalised{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_type: "mountain",
          gender: "M",
          entries: []
        }
      end

      def adjust_stage_leaderboard_factory do
        %AdjustStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid
        }
      end

      def stage_leaderboard_adjusted_factory do
        %StageLeaderboardAdjusted{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_type: "mountain",
          gender: "M",
          previous_entries: [],
          adjusted_entries: []
        }
      end

      def reset_stage_leaderboard_factory do
        %ResetStageLeaderboard{
          stage_leaderboard_uuid: @stage_leaderboard_uuid
        }
      end

      def stage_leaderboard_cleared_factory do
        %StageLeaderboardCleared{
          stage_leaderboard_uuid: @stage_leaderboard_uuid,
          challenge_uuid: @challenge_uuid
        }
      end

      def stage_leaderboard_entry_factory do
        %{
          rank: 1,
          athlete_uuid: "athlete-5704447",
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165,
          distance_in_metres: 937.3,
          elevation_gain_in_metres: 68.0
        }
      end
    end
  end
end
