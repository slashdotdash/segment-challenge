defmodule SegmentChallenge.Email do
  use Bamboo.Phoenix, view: SegmentChallenge.EmailView

  alias SegmentChallenge.Notifications.HostChallenge
  alias SegmentChallenge.Notifications.LostPlace

  @doc """
  Build a host challenge email

  ## Example

      host_challenge = %SegmentChallenge.Notifications.HostChallenge{
        athlete_uuid: "athlete-5704447",
        name: "Segment of the Month",
        challenge_uuid: "89455194-d80f-44f3-94b7-f85e41898e5f",
        url_slug: "winter-segment-challenge",
      }

      "example@segmentchallenge.com" |> SegmentChallenge.Email.host_challenge_email(host_challenge) |> SegmentChallenge.Email.Mailer.deliver_now()
  """
  def host_challenge_email(to, %HostChallenge{} = host_challenge) do
    base_email()
    |> to(to)
    |> bcc("ben@segmentchallenge.com")
    |> subject("Host #{host_challenge.name}")
    |> assign(:host_challenge, host_challenge)
    |> render(:host_challenge)
  end

  @doc """
  Construct a lost place in stage leaderboard email

  ## Example

      lost_place = %SegmentChallenge.Notifications.LostPlace{
        athlete_uuid: "athlete-123456",
        current_rank: 4,
        previous_rank: 3,
        taken_by_athlete: %{
          firstname: "Ben",
          lastname: "Smith",
          time_gap_in_seconds: 10,
        },
        leaderboard: %{name: "Men", gender: "M"},
        stage: %{name: "VCV Wherwell Hill", stage_number: 3, end_date: ~N[2017-05-31 23:59:59], url_slug: "vcv-wherwell-hill"},
      }

      lost_place = %SegmentChallenge.Notifications.LostPlace{
        athlete_uuid: "athlete-123456",
        current_rank: 5,
        previous_rank: 3,
        leaderboard: %{name: "Men", gender: "M"},
        stage: %{name: "VCV Wherwell Hill", stage_number: 3, end_date: ~N[2017-05-31 23:59:59], url_slug: "vcv-wherwell-hill"},
      }

      "example@segmentchallenge.com" |> SegmentChallenge.Email.lost_place_email(lost_place) |> SegmentChallenge.Email.Mailer.deliver_now()
  """
  def lost_place_email(to, %LostPlace{} = lost_place) do
    %LostPlace{
      taken_by_athlete: athlete,
      current_rank: current_rank,
      previous_rank: previous_rank,
      leaderboard: leaderboard,
      challenge: challenge,
      stage: stage
    } = lost_place

    base_email()
    |> to(to)
    |> subject(lost_place_subject(lost_place))
    |> assign(:athlete, athlete)
    |> assign(:current_rank, current_rank)
    |> assign(:previous_rank, previous_rank)
    |> assign(:leaderboard, leaderboard)
    |> assign(:challenge, challenge)
    |> assign(:stage, stage)
    |> render(:lost_place)
  end

  defp lost_place_subject(taken_by_athlete)

  defp lost_place_subject(%LostPlace{
         taken_by_athlete: nil,
         previous_rank: previous_rank,
         stage: stage
       }) do
    "You just lost #{Number.Human.number_to_ordinal(previous_rank)} place on Stage #{
      stage.stage_number
    } #{stage.name}"
  end

  defp lost_place_subject(%LostPlace{
         taken_by_athlete: athlete,
         previous_rank: previous_rank,
         stage: stage
       }) do
    "#{athlete.firstname} just stole your #{Number.Human.number_to_ordinal(previous_rank)} place on Stage #{
      stage.stage_number
    } #{stage.name}"
  end

  defp base_email do
    new_email()
    |> from("ben@segmentchallenge.com")
    |> put_header("reply-to", "ben@segmentchallenge.com")
    |> put_layout({SegmentChallengeWeb.LayoutView, :email})
  end
end
