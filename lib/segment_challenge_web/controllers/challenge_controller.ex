defmodule SegmentChallengeWeb.ChallengeController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Authorisation.Policies.ChallengePolicy
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesByStatusQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesCreatedByAthleteQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesEnteredByAthleteQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesHostedByAthleteClubsQuery
  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengeFilter
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Repo
  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated
  alias SegmentChallengeWeb.Plugs.EnsureChallengeHost
  alias SegmentChallengeWeb.Plugs.JoinedChallenges
  alias SegmentChallengeWeb.Plugs.IsClubMember

  plug(:set_active_section, :challenge)
  plug(:set_active_challenge_section, :active when action in [:index])
  plug(:set_active_challenge_section, :past when action in [:past])
  plug(:set_active_challenge_section, :clubs when action in [:clubs])
  plug(:set_active_challenge_section, :competing when action in [:competing])
  plug(:set_active_challenge_section, :hosted when action in [:hosted])
  plug(:set_active_challenge_section, :about when action in [:show])
  plug(EnsureAuthenticated when action in [:approve, :clubs, :competing, :edit, :hosted, :join])
  plug(EnsureChallengeHost when action in [:approve, :edit])
  plug(JoinedChallenges when action in [:index, :clubs, :competing, :hosted, :past])
  plug(IsClubMember when action in [:join])

  @doc """
  Challenges that are active or have yet to start.
  """
  def index(conn, params) do
    challenges =
      ["upcoming", "active"]
      |> ChallengesByStatusQuery.new()
      |> ChallengeFilter.by_type(Map.get(params, "type"))
      |> ChallengeFilter.by_activity(activity_type(params))
      |> Repo.paginate(params)

    render(conn, "index.html", challenges: challenges)
  end

  @doc """
  Challenges hosted by clubs the currently logged in athlete is a member of.
  """
  def clubs(conn, params) do
    challenges =
      conn
      |> current_athlete_uuid()
      |> ChallengesHostedByAthleteClubsQuery.new()
      |> ChallengeFilter.by_type(Map.get(params, "type"))
      |> ChallengeFilter.by_activity(activity_type(params))
      |> Repo.paginate(params)

    render(conn, "index.html", challenges: challenges)
  end

  @doc """
  Challenges the currently logged in athlete is competing in.
  """
  def competing(conn, params) do
    challenges =
      conn
      |> current_athlete_uuid()
      |> ChallengesEnteredByAthleteQuery.new()
      |> ChallengeFilter.by_type(Map.get(params, "type"))
      |> ChallengeFilter.by_activity(activity_type(params))
      |> Repo.paginate(params)

    render(conn, "index.html", challenges: challenges)
  end

  @doc """
  Challenges hosted by the currently logged in athlete.
  """
  def hosted(conn, params) do
    challenges =
      conn
      |> current_athlete_uuid()
      |> ChallengesCreatedByAthleteQuery.new()
      |> ChallengeFilter.by_type(Map.get(params, "type"))
      |> ChallengeFilter.by_activity(activity_type(params))
      |> Repo.paginate(params)

    render(conn, "index.html", challenges: challenges)
  end

  @doc """
  Challenges that have ended.
  """
  def past(conn, params) do
    challenges =
      ["past"]
      |> ChallengesByStatusQuery.new()
      |> ChallengeFilter.by_type(Map.get(params, "type"))
      |> ChallengeFilter.by_activity(activity_type(params))
      |> Repo.paginate(params)

    render(conn, "index.html", challenges: challenges)
  end

  @doc """
  Show an individual challenge.
  """
  def show(%{assigns: %{challenge: challenge}} = conn, _params) do
    stages = challenge.challenge_uuid |> StagesInChallengeQuery.new() |> Repo.all()
    active_stage = Enum.find(stages, fn stage -> stage.status == "active" end)

    render(
      conn,
      "show.html",
      stages: stages,
      active_stage: active_stage,
      commands: commands(conn, challenge)
    )
  end

  @doc """
  Approve a challenge's final leaderboards.
  """
  def approve(%{assigns: %{challenge: challenge}} = conn, _params) do
    stages = challenge.challenge_uuid |> StagesInChallengeQuery.new() |> Repo.all()

    render(
      conn,
      "approve.html",
      stages_approved?: Enum.all?(stages, & &1.approved),
      commands: commands(conn, challenge)
    )
  end

  @doc """
  Edit challenge description.
  """
  def edit(%{assigns: %{challenge: challenge}} = conn, _params) do
    case command(:set_challenge_description, conn, challenge) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(SegmentChallengeWeb.ErrorView)
        |> render("404.html")
        |> halt

      command ->
        conn
        |> include_script("/js/MarkdownEditor.js")
        |> render("edit.html",
          command: command,
          redirect_to: challenge_url(conn, :show, challenge.url_slug)
        )
    end
  end

  @doc """
  Host a challenge.
  """
  def host(%{assigns: %{challenge: challenge}} = conn, _params) do
    stages = StagesInChallengeQuery.new(challenge.challenge_uuid) |> Repo.all()

    render(conn, "host.html", stages: stages)
  end

  @doc """
  Join a challenge.
  """
  def join(%{assigns: %{challenge: challenge}} = conn, _params) do
    render(
      conn,
      "join.html",
      commands: commands(conn, challenge)
    )
  end

  # Get all authorised commands for the challenge.
  defp commands(%{assigns: %{current_athlete: nil}}, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, challenge) do
    ChallengePolicy.commands(struct(User, current_athlete), challenge)
  end

  # Get an authorised command by its name
  defp command(_name, %{assigns: %{current_athlete: nil}}, _challenge), do: nil

  defp command(name, %{assigns: %{current_athlete: current_athlete}}, challenge) do
    ChallengePolicy.command(name, struct(User, current_athlete), challenge)
  end

  defp activity_type(params) do
    case Map.get(params, "activity") do
      "ride" -> "Ride"
      "run" -> "Run"
      _activity -> nil
    end
  end
end
