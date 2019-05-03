defmodule SegmentChallenge.Stages.Stage.Aliases do
  defmacro __using__(_) do
    quote do
      alias SegmentChallenge.Stages.Stage.Commands.{
        AdjustStageDuration,
        AdjustStageIncludedActivities,
        ApproveStageLeaderboards,
        ChangeStageSegment,
        ConfigureAthleteGenderInStage,
        CreateActivityStage,
        CreateRaceStage,
        CreateSegmentStage,
        DeleteStage,
        EndStage,
        FlagStageEffort,
        ImportStageEfforts,
        IncludeCompetitorsInStage,
        MakePreviewStage,
        MakeQueenStage,
        PublishStageResults,
        RecordManualStageEffort,
        RemoveCompetitorFromStage,
        RemoveStageActivity,
        RevealStage,
        SetStageDescription,
        SetStageSegmentDetails,
        StartStage
      }

      alias SegmentChallenge.Events.{
        AthleteGenderAmendedInStage,
        CompetitorsJoinedStage,
        CompetitorRemovedFromStage,
        StageCreated,
        StageDeleted,
        StageDescriptionEdited,
        StageDurationAdjusted,
        StageEffortFlagged,
        StageEffortRecorded,
        StageEffortRemoved,
        StageEffortsCleared,
        StageEnded,
        StageGoalConfigured,
        StageIncludedActivitiesAdjusted,
        StageLeaderboardRequested,
        StageLeaderboardsApproved,
        StageMadePreview,
        StageMadeQueen,
        StageResultsPublished,
        StageRevealed,
        StageSegmentChanged,
        StageSegmentConfigured,
        StageStarted
      }
    end
  end
end
