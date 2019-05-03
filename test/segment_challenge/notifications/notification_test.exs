defmodule SegmentChallenge.Challenges.NotificationTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.ImportAthleteUseCase

  alias SegmentChallenge.Notifications

  alias SegmentChallenge.Commands.{
    ToggleEmailNotification
  }

  alias SegmentChallenge.Events.{
    AthleteSubscribedToAllNotifications,
    AthleteSubscribedToNotificationEmails,
    AthleteUnsubscribedFromNotificationEmails
  }

  alias SegmentChallenge.Notifications.AthleteNotifications
  alias SegmentChallenge.Router

  @tag :integration
  test "should not be subscribed when an athlete has not been imported" do
    refute Notifications.subscribed?("doesnotexist", :lost_place_notification)
  end

  describe "importing an athlete" do
    setup [
      :import_athlete
    ]

    @tag :integration
    test "should subscribe athlete to lost place email notifications", %{
      athlete_uuid: athlete_uuid
    } do
      wait_for_event(AthleteSubscribedToAllNotifications, fn event ->
        event.athlete_uuid == athlete_uuid
      end)

      assert Notifications.subscribed?(athlete_uuid, :lost_place_notification)
    end
  end

  describe "toggle lost place email notification" do
    setup [
      :import_athlete,
      :toggle_lost_place_email
    ]

    @tag :integration
    test "should unsubscribe athlete from lost place email notifications", %{
      athlete_uuid: athlete_uuid
    } do
      wait_for_event(AthleteUnsubscribedFromNotificationEmails, fn event ->
        event.notification_type == "lost_place" && event.athlete_uuid == athlete_uuid
      end)

      refute Notifications.subscribed?(athlete_uuid, :lost_place_notification)
    end
  end

  describe "toggle lost place email notification twice" do
    setup [
      :import_athlete,
      :toggle_lost_place_email,
      :toggle_lost_place_email
    ]

    @tag :integration
    test "should subscribe athlete to lost place email notifications", %{
      athlete_uuid: athlete_uuid
    } do
      wait_for_event(AthleteSubscribedToNotificationEmails, fn event ->
        event.notification_type == "lost_place" && event.athlete_uuid == athlete_uuid
      end)

      assert Notifications.subscribed?(athlete_uuid, :lost_place_notification)
    end
  end

  defp toggle_lost_place_email(%{athlete_uuid: athlete_uuid}) do
    wait_for_event(AthleteSubscribedToAllNotifications, fn event ->
      event.athlete_uuid == athlete_uuid
    end)

    :ok =
      Router.dispatch(%ToggleEmailNotification{
        athlete_notification_uuid: AthleteNotifications.identity(athlete_uuid),
        notification_type: "lost_place"
      })
  end
end
