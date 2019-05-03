defmodule SegmentChallenge.Notifications.Emails.LostPlaceTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import Ecto.Query
  import SegmentChallenge.Factory
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Notifications.LostPlace
  alias SegmentChallenge.Events.CompetitorsJoinedStage
  alias SegmentChallenge.Projections.EmailProjection
  alias SegmentChallenge.Infrastructure.DateTime.Now
  alias SegmentChallenge.{Repo, Router, Wait}

  setup do
    on_exit(fn ->
      Now.reset()
    end)

    :ok
  end

  describe "athlete loses place in stage leaderboard" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :import_two_segment_stage_efforts,
      :second_athlete_join_challenge,
      :wait_for_second_athlete_join_stage,
      :import_faster_stage_effort
    ]

    @tag :integration
    test "should send athlete a lost place email" do
      Wait.until(fn ->
        assert [_host_challenge_email, email] =
                 email_to_athlete("ben@segmentchallenge.com") |> Repo.all()

        assert email.to == "ben@segmentchallenge.com"
        assert email.type == "lost_place_email"
        assert email.send_status == "pending"

        # Should send 15 minutes later
        assert email.send_after == ~N[2016-01-01 00:15:00]

        lost_place = Poison.decode!(email.html_body, as: %LostPlace{}, keys: :atoms!)

        assert lost_place == %LostPlace{
                 athlete_uuid: "athlete-5704447",
                 occurred_at: lost_place.occurred_at,
                 previous_rank: 1,
                 current_rank: 2,
                 taken_by_athlete: %{
                   athlete_uuid: "athlete-123456",
                   firstname: "Strava",
                   lastname: "Athlete",
                   time_gap_in_seconds: 11
                 },
                 leaderboard: %{name: "Men", gender: "M"},
                 challenge: %{
                   name: "VC Venta Segment of the Month 2016",
                   url_slug: "vc-venta-segment-of-the-month-2016"
                 },
                 stage: %{
                   name: "VCV Sleepers Hill",
                   stage_number: 1,
                   end_date: "2016-01-31T23:59:59",
                   url_slug: "vcv-sleepers-hill"
                 }
               }
      end)
    end
  end

  @tag :unit
  test "should merge lost place notifications" do
    previous = %LostPlace{
      athlete_uuid: "athlete-5704447",
      occurred_at: "2016-01-07T19:16:29",
      previous_rank: 1,
      current_rank: 2,
      taken_by_athlete: %{
        athlete_uuid: "athlete-123456",
        firstname: "Ben",
        lastname: "Smith",
        time_gap_in_seconds: 10
      },
      leaderboard: %{
        name: "Men",
        gender: "M"
      },
      stage: %{
        name: "VCV Sleepers Hill",
        stage_number: 1,
        end_date: "2016-01-31T23:59:59",
        url_slug: "vcv-sleepers-hill"
      }
    }

    latest = %LostPlace{
      athlete_uuid: "athlete-5704447",
      occurred_at: "2016-01-07T20:16:29",
      previous_rank: 2,
      current_rank: 3,
      taken_by_athlete: %{
        athlete_uuid: "athlete-7890123",
        firstname: "Ben",
        lastname: "Smith",
        time_gap_in_seconds: 10
      },
      leaderboard: %{
        name: "Men",
        gender: "M"
      },
      stage: %{
        name: "VCV Sleepers Hill",
        stage_number: 1,
        end_date: "2016-01-31T23:59:59",
        url_slug: "vcv-sleepers-hill"
      }
    }

    assert LostPlace.merge(previous, latest) == %LostPlace{
             athlete_uuid: "athlete-5704447",
             occurred_at: "2016-01-07T19:16:29",
             previous_rank: 1,
             current_rank: 3,
             taken_by_athlete: nil,
             leaderboard: %{
               name: "Men",
               gender: "M"
             },
             stage: %{
               name: "VCV Sleepers Hill",
               stage_number: 1,
               end_date: "2016-01-31T23:59:59",
               url_slug: "vcv-sleepers-hill"
             }
           }
  end

  defp wait_for_second_athlete_join_stage(_context) do
    wait_for_event(CompetitorsJoinedStage, fn %CompetitorsJoinedStage{} = event ->
      %CompetitorsJoinedStage{competitors: competitors} = event

      Enum.any?(competitors, fn competitor -> competitor.athlete_uuid == "athlete-123456" end)
    end)

    :ok
  end

  defp import_faster_stage_effort(context) do
    %{stage_uuid: stage_uuid} = context

    dispatch(:import_stage_efforts,
      stage_uuid: stage_uuid,
      stage_efforts: [
        build(:import_stage_efforts_stage_effort,
          athlete_uuid: "athlete-123456",
          strava_activity_id: 2,
          strava_segment_effort_id: 2
        )
      ]
    )
  end

  defp dispatch(command, attrs) do
    command = build(command, attrs)

    Router.dispatch(command)
  end

  defp email_to_athlete(email) do
    from(e in EmailProjection, where: e.to == ^email)
  end
end
