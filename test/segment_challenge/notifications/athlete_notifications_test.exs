defmodule SegmentChallenge.Notifications.AthleteNotificationsTest do
  use ExUnit.Case

  import SegmentChallenge.Factory

  alias SegmentChallenge.Commands.{
    SubscribeAthleteToAllNotifications,
    ToggleEmailNotification,
  }
  alias SegmentChallenge.Events.{
    AthleteSubscribedToAllNotifications,
    AthleteSubscribedToNotificationEmails,
    AthleteUnsubscribedFromNotificationEmails,
  }
  alias SegmentChallenge.Notifications.AthleteNotifications

  @tag :unit
  test "subscribe athlete to all notifications" do
    assert_events [
        struct(SubscribeAthleteToAllNotifications, build(:athlete_notifications)),
      ], [
        struct(AthleteSubscribedToAllNotifications, build(:athlete_notifications)),
      ]
  end

  describe "toggle lost place email notification" do
    @tag :unit
    test "should unsubscribe athlete from email" do
      assert_events [
          struct(SubscribeAthleteToAllNotifications, build(:athlete_notifications)),
          struct(ToggleEmailNotification, build(:athlete_notifications, notification_type: "lost_place")),
        ], [
          struct(AthleteUnsubscribedFromNotificationEmails, build(:athlete_notifications, notification_type: "lost_place")),
        ]
    end

    @tag :unit
    test "should subscribe athlete to email when toggled again" do
      assert_events [
          struct(SubscribeAthleteToAllNotifications, build(:athlete_notifications)),
          struct(ToggleEmailNotification, build(:athlete_notifications, notification_type: "lost_place")),
          struct(ToggleEmailNotification, build(:athlete_notifications, notification_type: "lost_place")),
        ], [
          struct(AthleteSubscribedToNotificationEmails, build(:athlete_notifications, notification_type: "lost_place")),
        ]
    end
  end

  defp assert_events(commands, expected_events) do
    assert execute(commands) == expected_events
  end

  defp execute(commands) do
    {_, events} = Enum.reduce(commands, {%AthleteNotifications{}, []}, fn (command, {athlete_notification, _}) ->
      events = AthleteNotifications.execute(athlete_notification, command)

      {evolve(athlete_notification, events), events}
    end)

    List.wrap(events)
  end

  defp evolve(%AthleteNotifications{} = athlete_notifications, events) do
    Enum.reduce(List.wrap(events), athlete_notifications, &AthleteNotifications.apply(&2, &1))
  end
end
