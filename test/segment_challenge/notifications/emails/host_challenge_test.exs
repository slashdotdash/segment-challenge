defmodule SegmentChallenge.Notifications.Emails.HostChallengeTest do
  use SegmentChallenge.StorageCase

  import Ecto.Query
  import Commanded.Assertions.EventAssertions

  import SegmentChallenge.UseCases.{
    CreateChallengeUseCase,
    CreateStageUseCase
  }

  alias SegmentChallenge.Notifications.HostChallenge

  alias SegmentChallenge.Events.{
    ChallengeCreated
  }

  alias SegmentChallenge.Projections.{
    EmailProjection
  }

  alias SegmentChallenge.Infrastructure.DateTime.Now
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Wait

  setup do
    on_exit(fn ->
      Now.reset()
    end)

    :ok
  end

  describe "create challenge" do
    setup [
      :create_challenge
    ]

    @tag :integration
    test "should send athlete a host challenge email" do
      challenge_created = wait_for_event(ChallengeCreated)

      Wait.until(fn ->
        assert [email] = "ben@segmentchallenge.com" |> email_to_athlete() |> Repo.all()

        assert email.to == "ben@segmentchallenge.com"
        assert email.type == "host_challenge_email"
        assert email.send_status == "pending"

        # Should send immediately
        assert email.send_after == ~N[2016-01-01 00:00:00]

        host_challenge = Poison.decode!(email.html_body, as: %HostChallenge{}, keys: :atoms!)

        assert host_challenge == %HostChallenge{
                 athlete_uuid: "athlete-5704447",
                 name: "VC Venta Segment of the Month 2016",
                 challenge_uuid: challenge_created.data.challenge_uuid,
                 url_slug: "vc-venta-segment-of-the-month-2016"
               }
      end)
    end
  end

  describe "host challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    @tag :integration
    test "should discard unsent host challenge email" do
      Wait.until(fn ->
        assert [email] = "ben@segmentchallenge.com" |> email_to_athlete() |> Repo.all()

        assert email.to == "ben@segmentchallenge.com"
        assert email.type == "host_challenge_email"
        assert email.send_status == "discarded"
      end)
    end
  end

  defp email_to_athlete(email) do
    from(e in EmailProjection,
      where: e.to == ^email
    )
  end
end
