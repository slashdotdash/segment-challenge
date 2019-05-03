defmodule SegmentChallenge.Supervisor do
  use Supervisor

  alias SegmentChallenge.Challenges.AthleteChallengeParticipation
  alias SegmentChallenge.Challenges.ChallengeStageProcessManager
  alias SegmentChallenge.Leaderboards.ChallengeLeaderboardProcessManager
  alias SegmentChallenge.Leaderboards.StageLeaderboardProcessManager
  alias SegmentChallenge.Stages.StageCompetitorProcessManager
  alias SegmentChallenge.Challenges.Services.UrlSlugs.UniqueSlugger
  alias SegmentChallenge.Notifications.SubscribeAthleteToNotifications

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [
      # Projections
      supervisor(SegmentChallenge.ProjectionSupervisor, []),

      # URL slugs
      worker(UniqueSlugger, []),

      # Process managers
      worker(ChallengeLeaderboardProcessManager, [], restart: :temporary),
      worker(ChallengeStageProcessManager, [], restart: :temporary),
      worker(StageCompetitorProcessManager, [], restart: :temporary),
      worker(StageLeaderboardProcessManager, [], restart: :temporary),

      # Event handlers
      worker(AthleteChallengeParticipation, [], restart: :temporary),
      worker(SubscribeAthleteToNotifications, [], restart: :temporary),

      # Tasks
      supervisor(SegmentChallenge.Tasks.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
