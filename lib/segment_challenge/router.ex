defmodule SegmentChallenge.Router do
  use Commanded.Commands.Router

  alias SegmentChallenge.Athletes.{Athlete, AthleteCommandHandler}
  alias SegmentChallenge.Challenges.Challenge
  alias SegmentChallenge.Clubs.Club
  alias SegmentChallenge.Stages.Stage
  alias SegmentChallenge.Leaderboards.StageLeaderboard
  alias SegmentChallenge.Leaderboards.ChallengeLeaderboard
  alias SegmentChallenge.Notifications.AthleteNotifications

  if Mix.env() == :dev do
    middleware(Commanded.Middleware.Logger)
  end

  middleware(SegmentChallenge.Infrastructure.Validation.Middleware)

  identify(Athlete, by: :athlete_uuid)
  identify(AthleteNotifications, by: :athlete_notification_uuid)
  identify(Club, by: :club_uuid)
  identify(Challenge, by: :challenge_uuid)
  identify(Stage, by: :stage_uuid)
  identify(StageLeaderboard, by: :stage_leaderboard_uuid)
  identify(ChallengeLeaderboard, by: :challenge_leaderboard_uuid)

  dispatch(
    [
      SegmentChallenge.Commands.ImportAthlete,
      SegmentChallenge.Commands.ImportAthleteStarredStravaSegments,
      SegmentChallenge.Commands.JoinClub,
      SegmentChallenge.Commands.LeaveClub,
      SegmentChallenge.Commands.SetAthleteClubMemberships
    ],
    to: AthleteCommandHandler,
    aggregate: Athlete
  )

  dispatch([SegmentChallenge.Commands.ImportClub], to: Club)

  dispatch(
    [
      SegmentChallenge.Commands.AdjustChallengeDuration,
      SegmentChallenge.Commands.AdjustChallengeIncludedActivities,
      SegmentChallenge.Commands.AllowCompetitorParticipationInChallenge,
      SegmentChallenge.Commands.ApproveChallengeLeaderboards,
      SegmentChallenge.Commands.CancelChallenge,
      SegmentChallenge.Commands.CreateChallenge,
      SegmentChallenge.Commands.EndChallenge,
      SegmentChallenge.Commands.ExcludeCompetitorFromChallenge,
      SegmentChallenge.Commands.HostChallenge,
      SegmentChallenge.Commands.IncludeStageInChallenge,
      SegmentChallenge.Commands.JoinChallenge,
      SegmentChallenge.Commands.LeaveChallenge,
      SegmentChallenge.Commands.LimitCompetitorParticipationInChallenge,
      SegmentChallenge.Commands.PublishChallengeResults,
      SegmentChallenge.Commands.RemoveStageFromChallenge,
      SegmentChallenge.Commands.RenameChallenge,
      SegmentChallenge.Commands.SetChallengeDescription,
      SegmentChallenge.Commands.StartChallenge
    ],
    to: Challenge
  )

  dispatch(
    [
      Stage.Commands.AdjustStageDuration,
      Stage.Commands.AdjustStageIncludedActivities,
      Stage.Commands.ApproveStageLeaderboards,
      Stage.Commands.ChangeStageSegment,
      Stage.Commands.ConfigureAthleteGenderInStage,
      Stage.Commands.CreateActivityStage,
      Stage.Commands.CreateRaceStage,
      Stage.Commands.DeleteStage,
      Stage.Commands.EndStage,
      Stage.Commands.FlagStageEffort,
      Stage.Commands.ImportStageEfforts,
      Stage.Commands.IncludeCompetitorsInStage,
      Stage.Commands.MakeQueenStage,
      Stage.Commands.MakePreviewStage,
      Stage.Commands.PublishStageResults,
      Stage.Commands.RecordManualStageEffort,
      Stage.Commands.RemoveCompetitorFromStage,
      Stage.Commands.RemoveStageActivity,
      Stage.Commands.RevealStage,
      Stage.Commands.SetStageSegmentDetails,
      Stage.Commands.SetStageDescription,
      Stage.Commands.StartStage
    ],
    to: Stage,
    timeout: 60_000
  )

  dispatch(
    [
      Stage.Commands.CreateSegmentStage
    ],
    to: Stage,
    timeout: 300_000
  )

  dispatch(
    [
      SegmentChallenge.Commands.AdjustStageLeaderboard,
      SegmentChallenge.Commands.CreateStageLeaderboard,
      SegmentChallenge.Commands.FinaliseStageLeaderboard,
      SegmentChallenge.Commands.RankStageEffortInStageLeaderboard,
      SegmentChallenge.Commands.RankStageEffortsInStageLeaderboard,
      SegmentChallenge.Commands.RemoveCompetitorFromStageLeaderboard,
      SegmentChallenge.Commands.ResetStageLeaderboard,
      SegmentChallenge.Commands.RemoveStageEffortFromStageLeaderboard,
      SegmentChallenge.Commands.SetStageLeaderboardPointsAdjustment
    ],
    to: StageLeaderboard
  )

  dispatch(
    [
      SegmentChallenge.Commands.CreateChallengeLeaderboard,
      SegmentChallenge.Commands.AdjustAthletePointsInChallengeLeaderboard,
      SegmentChallenge.Commands.AdjustPointsFromStageLeaderboard,
      SegmentChallenge.Commands.AllowCompetitorPointScoringInChallengeLeaderboard,
      SegmentChallenge.Commands.AssignPointsFromStageLeaderboard,
      SegmentChallenge.Commands.RemoveCompetitorFromChallengeLeaderboard,
      SegmentChallenge.Commands.RemoveChallengeLeaderboard,
      SegmentChallenge.Commands.ReconfigureChallengeLeaderboardPoints,
      SegmentChallenge.Commands.FinaliseChallengeLeaderboard,
      SegmentChallenge.Commands.LimitCompetitorPointScoringInChallengeLeaderboard
    ],
    to: ChallengeLeaderboard
  )

  dispatch(
    [
      SegmentChallenge.Commands.SubscribeAthleteToAllNotifications,
      SegmentChallenge.Commands.ToggleEmailNotification,
      SegmentChallenge.Commands.UpdateAthleteNotificationEmail
    ],
    to: AthleteNotifications
  )
end
