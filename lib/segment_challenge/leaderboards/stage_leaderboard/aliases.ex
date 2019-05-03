defmodule SegmentChallenge.Leaderboards.StageLeaderboard.Aliases do
  defmacro __using__(_) do
    quote do
      alias SegmentChallenge.Commands.{
        AdjustStageLeaderboard,
        CreateStageLeaderboard,
        FinaliseStageLeaderboard,
        RankStageEffortInStageLeaderboard,
        RankStageEffortsInStageLeaderboard,
        RemoveCompetitorFromStageLeaderboard,
        RemoveStageEffortFromStageLeaderboard,
        ResetStageLeaderboard,
        SetStageLeaderboardPointsAdjustment
      }

      alias SegmentChallenge.Events.{
        AthleteAchievedStageGoal,
        AthleteRankedInStageLeaderboard,
        AthleteRecordedImprovedStageEffort,
        AthleteRecordedWorseStageEffort,
        AthleteRemovedFromStageLeaderboard,
        PendingAdjustmentInStageLeaderboard,
        StageEffortRemovedFromStageLeaderboard,
        StageLeaderboardAdjusted,
        StageLeaderboardCreated,
        StageLeaderboardCleared,
        StageLeaderboardRanked,
        StageLeaderboardFinalised,
        StageLeaderboardPointsAdjusted
      }
    end
  end
end
