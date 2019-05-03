defmodule SegmentChallenge.Notifications.SubscribeAthleteToNotifications do
  use Commanded.Event.Handler, name: "SubscribeAthleteToNotifications"

  alias SegmentChallenge.Commands.SubscribeAthleteToAllNotifications
  alias SegmentChallenge.Commands.UpdateAthleteNotificationEmail
  alias SegmentChallenge.Events.AthleteEmailChanged
  alias SegmentChallenge.Events.AthleteImported
  alias SegmentChallenge.Notifications.AthleteNotifications
  alias SegmentChallenge.Router

  def handle(%AthleteImported{email: nil}, _metadata), do: :ok
  def handle(%AthleteImported{email: ""}, _metadata), do: :ok

  def handle(%AthleteImported{} = event, _metadata) do
    %AthleteImported{athlete_uuid: athlete_uuid, email: email} = event

    command = %SubscribeAthleteToAllNotifications{
      athlete_notification_uuid: AthleteNotifications.identity(athlete_uuid),
      athlete_uuid: athlete_uuid,
      email: email
    }

    Router.dispatch(command)
  end

  def handle(%AthleteEmailChanged{} = event, _metadata) do
    %AthleteEmailChanged{athlete_uuid: athlete_uuid, email: email} = event

    command = %UpdateAthleteNotificationEmail{
      athlete_notification_uuid: AthleteNotifications.identity(athlete_uuid),
      athlete_uuid: athlete_uuid,
      email: email
    }

    Router.dispatch(command)
  end
end
