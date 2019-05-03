defmodule SegmentChallengeWeb.PageController do
  use SegmentChallengeWeb, :controller

  plug(:put_layout, "home.html" when action in [:index])
  plug(:put_layout, "app.html" when action in [:about, :terms, :privacy, :cookies])

  alias SegmentChallenge.Challenges.Queries.ActivityFeeds.AllActivityFeedQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesByStatusQuery
  alias SegmentChallenge.Repo

  def index(conn, _params) do
    recent_activity = AllActivityFeedQuery.new(10) |> Repo.all()

    active_challenges =
      ["upcoming", "active"]
      |> ChallengesByStatusQuery.random(10)
      |> Repo.all()
      |> Enum.sort_by(& &1.name)

    render(conn, "index.html",
      recent_activity: recent_activity,
      active_challenges: active_challenges
    )
  end

  def about(conn, _params) do
    render(conn, "about.html")
  end

  def cookies(conn, _params) do
    render(conn, "cookies.html")
  end

  def faq(conn, _params) do
    render(conn, "faq.html")
  end

  def news(conn, _params) do
    render(conn, "news.html")
  end

  def privacy(conn, _params) do
    render(conn, "privacy.html")
  end

  def terms(conn, _params) do
    render(conn, "terms.html")
  end
end
