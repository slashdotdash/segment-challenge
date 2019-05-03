defmodule SegmentChallengeWeb.DashboardController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Challenges.Queries.ActivityFeeds.AthleteDashboardActivityFeedQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesCreatedByAthleteQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesEnteredByAthleteQuery
  alias SegmentChallenge.Repo
  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(:set_active_section, :dashboard)
  plug(:set_active_dashboard_section, :overview when action in [:index])
  plug(EnsureAuthenticated)

  def index(conn, params) do
    current_athlete_uuid = current_athlete_uuid(conn)

    joined_challenges =
      current_athlete_uuid |> ChallengesEnteredByAthleteQuery.new() |> Repo.all()

    hosted_challenges =
      current_athlete_uuid |> ChallengesCreatedByAthleteQuery.new() |> Repo.all()

    challenge_uuids =
      MapSet.union(
        MapSet.new(joined_challenges, & &1.challenge_uuid),
        MapSet.new(hosted_challenges, & &1.challenge_uuid)
      )
      |> Enum.to_list()

    # Get athlete's activity, including any joined and/or hosted challenges
    activities = paginate_feed_query(current_athlete_uuid, challenge_uuids, params)

    render(conn, "index.html",
      activities: activities,
      joined_challenges: joined_challenges,
      hosted_challenges: hosted_challenges
    )
  end

  def paginate_feed_query(athlete_uuid, challenge_uuids, params) do
    AthleteDashboardActivityFeedQuery.new(athlete_uuid, challenge_uuids) |> Repo.next_page(params)
  end
end
