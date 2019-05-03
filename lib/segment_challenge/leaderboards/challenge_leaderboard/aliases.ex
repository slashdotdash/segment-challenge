defmodule SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases do
  defmacro __using__(_) do
    quote do
      alias SegmentChallenge.Commands.{
        AdjustAthletePointsInChallengeLeaderboard,
        AdjustPointsFromStageLeaderboard,
        AllowCompetitorPointScoringInChallengeLeaderboard,
        AssignPointsFromStageLeaderboard,
        CreateChallengeLeaderboard,
        FinaliseChallengeLeaderboard,
        LimitCompetitorPointScoringInChallengeLeaderboard,
        RemoveCompetitorFromChallengeLeaderboard,
        RemoveChallengeLeaderboard,
        ReconfigureChallengeLeaderboardPoints
      }

      alias SegmentChallenge.Events.{
        AthleteAccumulatedActivityInChallengeLeaderboard,
        AthleteAccumulatedPointsInChallengeLeaderboard,
        AthleteAchievedChallengeGoal,
        AthleteActivityAdjustedInChallengeLeaderboard,
        AthletePointsAdjustedInChallengeLeaderboard,
        AthleteRemovedFromChallengeLeaderboard,
        ChallengeLeaderboardCreated,
        ChallengeLeaderboardFinalised,
        ChallengeLeaderboardPointsReconfigured,
        ChallengeLeaderboardRanked,
        ChallengeLeaderboardRemoved,
        CompetitorScoringInChallengeLeaderboardLimited,
        CompetitorScoringInChallengeLeaderboardAllowed
      }
    end
  end
end
