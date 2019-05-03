defmodule SegmentChallenge.ChallengeLeaderboardFactory do
  use SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases

  defmacro __using__(_opts) do
    quote do
      @challenge_leaderboard_uuid UUID.uuid4()
      @challenge_uuid UUID.uuid4()
      @stage_uuid UUID.uuid4()
      @athlete_uuid "athlete1"

      def create_challenge_leaderboard_factory do
        %CreateChallengeLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_type: "segment",
          challenge_uuid: @challenge_uuid,
          name: "GC",
          description: "General classification",
          gender: "M",
          rank_by: "points",
          rank_order: "desc",
          points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1],
          has_goal: false
        }
      end

      def challenge_leaderboard_created_factory do
        %ChallengeLeaderboardCreated{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          challenge_type: "segment",
          name: "GC",
          description: "General classification",
          gender: "M",
          rank_by: "points",
          rank_order: "desc",
          points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1],
          has_goal?: false
        }
      end

      def assign_points_from_stage_leaderboard_factory do
        %AssignPointsFromStageLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          challenge_stage_uuids: [@stage_uuid],
          stage_uuid: @stage_uuid,
          stage_type: "mountain",
          points_adjustment: nil,
          entries: [
            %{rank: 1, value: 165, athlete_uuid: @athlete_uuid}
          ]
        }
      end

      def athlete_accumulated_points_in_challenge_leaderboard_factory do
        %AthleteAccumulatedPointsInChallengeLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_type: "segment",
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          gender: "M",
          points: 15
        }
      end

      def athlete_accumulated_activity_in_challenge_leaderboard_factory do
        %AthleteAccumulatedActivityInChallengeLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_type: "distance",
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          athlete_uuid: @athlete_uuid,
          gender: "M",
          elapsed_time_in_seconds: 188,
          moving_time_in_seconds: 188,
          distance_in_metres: 937.3,
          elevation_gain_in_metres: 68.0,
          goals: nil,
          goal_progress: nil
        }
      end

      def challenge_leaderbord_ranked_factory do
        %ChallengeLeaderboardRanked{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          new_entries: [
            %ChallengeLeaderboardRanked.Ranking{
              athlete_uuid: @athlete_uuid,
              rank: 1
            }
          ]
        }
      end

      def reconfigure_challenge_leaderboard_points_factory do
        %ReconfigureChallengeLeaderboardPoints{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1]
        }
      end

      def challenge_leaderboard_points_reconfigured_factory do
        %ChallengeLeaderboardPointsReconfigured{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1]
        }
      end

      def adjust_points_from_stage_leaderboard_factory do
        %AdjustPointsFromStageLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          stage_type: "mountain",
          previous_entries: [
            %{rank: 1, value: 165, athlete_uuid: @athlete_uuid}
          ],
          adjusted_entries: [
            %{rank: 1, value: 155, athlete_uuid: "athlete2"},
            %{rank: 2, value: 165, athlete_uuid: @athlete_uuid}
          ]
        }
      end

      def adjust_athlete_points_in_challenge_leaderboard_factory do
        %AdjustAthletePointsInChallengeLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          athlete_uuid: "athlete1",
          points_adjustment: -5
        }
      end

      def athlete_points_adjusted_in_challenge_leaderboard_factory do
        %AthletePointsAdjustedInChallengeLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          gender: "M",
          points_adjustment: -15
        }
      end

      def athlete_removed_from_challenge_leaderboard_factory do
        %AthleteRemovedFromChallengeLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          athlete_uuid: @athlete_uuid,
          rank: 1
        }
      end

      def limit_competitor_point_scoring_in_challenge_leaderboard_factory do
        %LimitCompetitorPointScoringInChallengeLeaderboard{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          athlete_uuid: @athlete_uuid,
          reason: "Not a 1st claim club member"
        }
      end

      def competitor_scoring_in_challenge_leaderboard_limited_factory do
        %CompetitorScoringInChallengeLeaderboardLimited{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          athlete_uuid: @athlete_uuid,
          reason: "Not a 1st claim club member"
        }
      end

      def athlete_achieved_challenge_goal_factory do
        %AthleteAchievedChallengeGoal{
          challenge_leaderboard_uuid: @challenge_leaderboard_uuid,
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid
        }
      end
    end
  end
end
