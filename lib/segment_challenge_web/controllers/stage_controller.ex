defmodule SegmentChallengeWeb.StageController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Authorisation.Policies.StagePolicy
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallengeWeb.CreateStageBuilder

  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated
  alias SegmentChallengeWeb.Plugs.EnsureChallengeHost
  alias SegmentChallengeWeb.Plugs.IsClubMember
  alias SegmentChallengeWeb.Plugs.JoinedChallenges

  plug(:set_active_section, :challenge)
  plug(:set_active_stage_section, :about when action in [:show])
  plug(EnsureAuthenticated when action in [:new])
  plug(EnsureChallengeHost when action in [:new])
  plug(IsClubMember when action in [:missing_attempt])
  plug(JoinedChallenges when action in [:missing_attempt])

  def show(%{assigns: %{stage: stage, challenge: challenge}} = conn, _params) do
    conn
    |> include_script("/js/map.js")
    |> render("show.html", commands: commands(conn, stage, challenge))
  end

  def new(%{assigns: %{challenge: challenge}} = conn, params) do
    conn
    |> include_script("/js/CreateStage.js")
    |> Plug.Conn.assign(:redirect_to, challenge_stage_url(conn, :show, challenge.url_slug))
    |> render("new.html", create_stage: CreateStageBuilder.new(conn, params))
  end

  @doc """
  Edit stage description.
  """
  def edit(%{assigns: %{stage: stage, challenge: challenge}} = conn, _params) do
    case command(:set_stage_description, conn, stage, challenge) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(SegmentChallengeWeb.ErrorView)
        |> render("404.html")
        |> halt()

      command ->
        conn
        |> include_script("/js/MarkdownEditor.js")
        |> render(
          "edit.html",
          command: command,
          redirect_to: stage_url(conn, :show, challenge.url_slug, stage.url_slug)
        )
    end
  end

  def missing_attempt(%{assigns: assigns} = conn, _params) do
    %{
      challenge: %ChallengeProjection{challenge_uuid: challenge_uuid},
      is_club_member: is_club_member,
      joined_challenges: joined_challenges,
      current_athlete: current_athlete
    } = assigns

    has_set_gender =
      case current_athlete do
        %{gender: gender} when gender in ["M", "F"] -> true
        _athlete -> false
      end

    render(
      conn,
      "missing_attempt.html",
      has_joined_club: is_club_member,
      is_authenticated: current_athlete != nil,
      has_joined_challenge: MapSet.member?(joined_challenges, challenge_uuid),
      has_set_gender: has_set_gender
    )
  end

  # Get an authorised command by name.
  defp command(_name, %{assigns: %{current_athlete: nil}}, _stage, _challenge), do: nil

  defp command(name, %{assigns: %{current_athlete: current_athlete}}, stage, challenge) do
    StagePolicy.command(name, struct(User, current_athlete), stage, challenge)
  end

  defp commands(%{assigns: %{current_athlete: nil}}, _stage, _challenge), do: []

  defp commands(%{assigns: %{current_athlete: current_athlete}}, stage, challenge) do
    StagePolicy.commands(struct(User, current_athlete), stage, challenge)
  end
end
