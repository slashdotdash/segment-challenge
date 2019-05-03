defmodule SegmentChallenge.Projections.Challenges.ChallengeProjectionTest do
  use SegmentChallenge.StorageCase

  import Ecto.Query
  import SegmentChallenge.Factory
  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.ApproveChallengeLeaderboardsUseCase
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Commands.{RenameChallenge, SetChallengeDescription}

  alias SegmentChallenge.Events.{
    ChallengeApproved,
    ChallengeCreated,
    ChallengeDescriptionEdited,
    ChallengeRenamed,
    CompetitorLeftChallenge
  }

  alias SegmentChallenge.Projections.{ChallengeCompetitorProjection, ChallengeProjection}
  alias SegmentChallenge.{Repo, Router, Wait}

  @moduletag :integration
  @moduletag :projection

  describe "creating a challenge" do
    setup [
      :create_challenge
    ]

    test "should create challenge projection", context do
      wait_for_event(ChallengeCreated, fn event ->
        event.challenge_uuid == context[:challenge_uuid]
      end)

      expected_challenge = build(:challenge)

      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge != nil
        assert challenge.name == expected_challenge.name
        assert challenge.start_date == ~N[2016-01-01 00:00:00]
        assert challenge.start_date_local == ~N[2016-01-01 00:00:00]
        assert challenge.end_date == ~N[2016-10-31 23:59:59]
        assert challenge.end_date_local == ~N[2016-10-31 23:59:59]
        assert challenge.created_by_athlete_uuid == context[:athlete_uuid]
        assert challenge.created_by_athlete_name == "Ben Smith"
        assert challenge.hosted_by_club_uuid == context[:club_uuid]
        assert challenge.hosted_by_club_name == "VC Venta"
        assert challenge.private == false
        assert challenge.status == "pending"
        assert challenge.stages_configured == false

        assert challenge.description_markdown == """
               A friendly competition open to VC Venta members.
               Each month the organiser will nominate a Strava segment.
               Whoever records the fastest time (male and female) over the segment is the winner.

               Placings contribute to the overall competitions.
               """

        assert challenge.description_html ==
                 "<p>A friendly competition open to VC Venta members.\nEach month the organiser will nominate a Strava segment.\nWhoever records the fastest time (male and female) over the segment is the winner.</p>\n<p>Placings contribute to the overall competitions.</p>\n"

        assert challenge.summary_html ==
                 "<p>A friendly competition open to VC Venta members.</p>\n"
      end)
    end
  end

  describe "creating a challenge for a private Strava club" do
    setup [
      :create_private_challenge
    ]

    test "should create challenge projection", %{challenge_uuid: challenge_uuid} do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, challenge_uuid)

        refute is_nil(challenge)
        assert challenge.private == true
      end)
    end
  end

  describe "including a stage" do
    setup [
      :create_challenge,
      :create_final_stage
    ]

    test "should create challenge projection", %{challenge_uuid: challenge_uuid} do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, challenge_uuid)

        refute is_nil(challenge)
        assert challenge.stages_configured
      end)
    end
  end

  describe "approving a challenge" do
    setup [
      :create_future_challenge,
      :host_challenge
    ]

    test "should create challenge projection", context do
      wait_for_event(ChallengeApproved, fn event ->
        event.challenge_uuid == context[:challenge_uuid]
      end)

      expected_challenge = build(:challenge)

      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge != nil
        assert challenge.name == expected_challenge.name
        assert challenge.status == "active"
      end)
    end
  end

  describe "joining a challenge" do
    setup [
      :create_challenge,
      :host_challenge,
      :athlete_join_challenge
    ]

    test "should include competitors in competitor challenge projection", %{
      challenge_uuid: challenge_uuid
    } do
      Wait.until(fn ->
        competitors = query_challenge_competitors(challenge_uuid) |> Repo.all()
        refute competitors == []
      end)
    end
  end

  describe "starting a challenge" do
    setup [
      :create_challenge,
      :host_challenge
    ]

    test "should create challenge projection", context do
      expected_challenge = build(:challenge)

      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge != nil
        assert challenge.name == expected_challenge.name
        assert challenge.start_date == ~N[2016-01-01 00:00:00]
        assert challenge.start_date_local == ~N[2016-01-01 00:00:00]
        assert challenge.end_date == ~N[2016-10-31 23:59:59]
        assert challenge.end_date_local == ~N[2016-10-31 23:59:59]
        assert challenge.created_by_athlete_uuid == context[:athlete_uuid]
        assert challenge.created_by_athlete_name == "Ben Smith"
        assert challenge.hosted_by_club_uuid == context[:club_uuid]
        assert challenge.hosted_by_club_name == "VC Venta"
        assert challenge.status == "active"
      end)
    end
  end

  describe "adjusting a challenge duration" do
    setup [
      :create_challenge,
      :host_challenge,
      :adjust_challenge_duration
    ]

    test "should update challenge start/end dates", context do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge.start_date == ~N[2016-01-02 00:00:00]
        assert challenge.start_date_local == ~N[2016-01-02 00:00:00]
        assert challenge.end_date == ~N[2016-10-30 23:59:59]
        assert challenge.end_date_local == ~N[2016-10-30 23:59:59]
      end)
    end
  end

  describe "set challenge description" do
    setup [
      :create_challenge,
      :host_challenge,
      :set_challenge_description
    ]

    test "should update challenge description", context do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge.description_markdown == "Updated description"
        assert challenge.description_html == "<p>Updated description</p>\n"
        assert challenge.summary_html == "<p>Updated description</p>\n"
      end)
    end

    defp set_challenge_description(context) do
      :ok =
        Router.dispatch(%SetChallengeDescription{
          challenge_uuid: context[:challenge_uuid],
          description: "Updated description",
          updated_by_athlete_uuid: context[:athlete_uuid]
        })

      wait_for_event(ChallengeDescriptionEdited, fn event ->
        event.challenge_uuid == context[:challenge_uuid]
      end)

      context
    end
  end

  describe "rename challenge" do
    setup [
      :create_challenge,
      :rename_challenge
    ]

    test "should update name and URL slug", context do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge != nil
        assert challenge.name == "VC Venta Segment of the Month 2017"
        assert challenge.url_slug == "vc-venta-segment-of-the-month-2017"
      end)
    end

    defp rename_challenge(context) do
      :ok =
        Router.dispatch(%RenameChallenge{
          challenge_uuid: context[:challenge_uuid],
          name: "VC Venta Segment of the Month 2017",
          renamed_by_athlete_uuid: context[:athlete_uuid]
        })

      wait_for_event(ChallengeRenamed, fn event ->
        event.challenge_uuid == context[:challenge_uuid]
      end)

      context
    end
  end

  describe "cancel challenge" do
    setup [
      :create_challenge,
      :cancel_challenge
    ]

    test "should delete challenge", context do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge == nil
      end)
    end
  end

  describe "approving challenge leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :end_challenge,
      :approve_stage_leaderboards,
      :approve_challenge_leaderboards
    ]

    test "should approve challenge projection and set approval message", context do
      Wait.until(fn ->
        challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

        assert challenge != nil
        assert challenge.status == "past"
        assert challenge.approved == true
        assert challenge.results_markdown == "Congratulations to Ben for winning the competition."

        assert challenge.results_html ==
                 "<p>Congratulations to Ben for winning the competition.</p>\n"
      end)
    end
  end

  describe "athlete leaves challenge" do
    setup [
      :create_challenge,
      :athlete_join_challenge,
      :athlete_leave_challenge
    ]

    test "should remove athlete from challenge competitors", %{
      athlete_uuid: athlete_uuid,
      challenge_uuid: challenge_uuid
    } do
      wait_for_event(CompetitorLeftChallenge, fn event -> event.athlete_uuid == athlete_uuid end)

      Wait.until(fn ->
        assert query_challenge_competitors(challenge_uuid) |> Repo.all() == []
      end)
    end
  end

  defp query_challenge_competitors(challenge_uuid) do
    from(c in ChallengeCompetitorProjection,
      where: c.challenge_uuid == ^challenge_uuid
    )
  end
end
