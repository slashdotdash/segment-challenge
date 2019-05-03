defmodule SegmentChallenge.Challenges.Challenge.Aliases do
  defmacro __using__(_) do
    quote do
      alias SegmentChallenge.Commands.{
        AdjustChallengeDuration,
        AdjustChallengeIncludedActivities,
        AllowCompetitorParticipationInChallenge,
        ApproveChallenge,
        ApproveChallengeLeaderboards,
        CancelChallenge,
        CreateChallenge,
        EndChallenge,
        ExcludeCompetitorFromChallenge,
        HostChallenge,
        JoinChallenge,
        IncludeStageInChallenge,
        LimitCompetitorParticipationInChallenge,
        PublishChallengeResults,
        LeaveChallenge,
        RemoveStageFromChallenge,
        RenameChallenge,
        SetChallengeDescription,
        StartChallenge
      }

      alias SegmentChallenge.Events.{
        ChallengeCancelled,
        ChallengeCreated,
        ChallengeRenamed,
        ChallengeStageRequested,
        ChallengeStagesConfigured,
        ChallengeStageStartRequested,
        ChallengeHosted,
        ChallengeIncludedActivitiesAdjusted,
        ChallengeApproved,
        ChallengeLeaderboardRequested,
        ChallengeResultsPublished,
        ChallengeStarted,
        ChallengeEnded,
        ChallengeGoalConfigured,
        ChallengeLeaderboardsApproved,
        ChallengeDurationAdjusted,
        ChallengeDescriptionEdited,
        CompetitorExcludedFromChallenge,
        CompetitorJoinedChallenge,
        CompetitorsJoinedChallenge,
        CompetitorLeftChallenge,
        CompetitorParticipationInChallengeAllowed,
        CompetitorParticipationInChallengeLimited,
        StageIncludedInChallenge,
        StageRemovedFromChallenge
      }
    end
  end
end
