defmodule SegmentChallenge.ProjectionSupervisor do
  use Supervisor

  alias SegmentChallenge.Projections

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  def init(_) do
    children = [
      worker(Projections.ActivityFeedProjector, [], restart: :temporary),
      worker(Projections.AthleteCompetitorProjection.Builder, [], restart: :temporary),
      worker(Projections.ChallengeLeaderboardProjector, [], restart: :temporary),
      worker(Projections.ChallengeProjector, [], restart: :temporary),
      worker(Projections.Clubs.Builder, [], restart: :temporary),
      worker(Projections.NotificationProjection.Builder, [], restart: :temporary),
      worker(Projections.Profiles.ProfileProjection.Builder, [], restart: :temporary),
      worker(Projections.StageProjector, [], restart: :temporary),
      worker(Projections.StageEffortProjector, [], restart: :temporary),
      worker(Projections.Slugs.UrlSlugProjection.Builder, [], restart: :temporary),
      worker(SegmentChallenge.Athletes.Projections.BadgeProjector, [], restart: :temporary),
      worker(SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjector, [],
        restart: :temporary
      ),
      worker(SegmentChallenge.Leaderboards.StageLeaderboard.StageResultsProjector, [],
        restart: :temporary
      )
    ]

    supervise(children, strategy: :one_for_one)
  end
end
