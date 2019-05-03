defmodule SegmentChallenge.Notifications.AthleteNotifications do
  @moduledoc """
  Notifications for an athlete
  """

  defstruct [:athlete_notification_uuid, :athlete_uuid, :email, notifications: %{}]

  alias SegmentChallenge.Commands.{
    SubscribeAthleteToAllNotifications,
    ToggleEmailNotification,
    UpdateAthleteNotificationEmail
  }

  alias SegmentChallenge.Events.{
    AthleteSubscribedToAllNotifications,
    AthleteSubscribedToNotificationEmails,
    AthleteUnsubscribedFromNotificationEmails,
    AthleteNotificationEmailChanged
  }

  alias SegmentChallenge.Notifications.AthleteNotifications

  def identity(athlete_uuid), do: "#{athlete_uuid}-notifications"

  @doc """
  Subscribe an athlete to all relevant notifications
  """
  def execute(
        %AthleteNotifications{athlete_notification_uuid: nil},
        %SubscribeAthleteToAllNotifications{} = command
      ) do
    %SubscribeAthleteToAllNotifications{
      athlete_notification_uuid: athlete_notification_uuid,
      athlete_uuid: athlete_uuid,
      email: email
    } = command

    %AthleteSubscribedToAllNotifications{
      athlete_notification_uuid: athlete_notification_uuid,
      athlete_uuid: athlete_uuid,
      email: email
    }
  end

  def execute(%AthleteNotifications{}, %SubscribeAthleteToAllNotifications{}), do: []

  @doc """
  Update an athlete's email for notifications
  """
  def execute(%AthleteNotifications{email: email}, %UpdateAthleteNotificationEmail{email: email}),
    do: []

  def execute(
        %AthleteNotifications{athlete_notification_uuid: nil},
        %UpdateAthleteNotificationEmail{} = update
      ) do
    %AthleteSubscribedToAllNotifications{
      athlete_notification_uuid: update.athlete_notification_uuid,
      athlete_uuid: update.athlete_uuid,
      email: update.email
    }
  end

  def execute(
        %AthleteNotifications{
          athlete_notification_uuid: athlete_notification_uuid,
          athlete_uuid: athlete_uuid
        },
        %UpdateAthleteNotificationEmail{athlete_uuid: athlete_uuid, email: email}
      ) do
    %AthleteNotificationEmailChanged{
      athlete_notification_uuid: athlete_notification_uuid,
      athlete_uuid: athlete_uuid,
      email: email
    }
  end

  @doc """
  Subscribe/unsubscribe to/from notification emails of the given type
  """
  def execute(
        %AthleteNotifications{} = athlete_notification,
        %ToggleEmailNotification{notification_type: notification_type}
      )
      when notification_type in ["approve_leaderboards", "host_challenge", "lost_place"] do
    toggle_subscription(athlete_notification, notification_type)
  end

  # state mutators

  def apply(
        %AthleteNotifications{} = athlete_notifications,
        %AthleteSubscribedToAllNotifications{athlete_notification_uuid: athlete_notification_uuid} =
          athlete_subscribed
      ) do
    %AthleteNotifications{
      athlete_notifications
      | athlete_notification_uuid: athlete_notification_uuid,
        athlete_uuid: athlete_subscribed.athlete_uuid,
        email: athlete_subscribed.email
    }
  end

  def apply(
        %AthleteNotifications{} = athlete_notifications,
        %AthleteNotificationEmailChanged{email: email}
      ) do
    %AthleteNotifications{athlete_notifications | email: email}
  end

  def apply(
        %AthleteNotifications{notifications: notifications} = athlete_notifications,
        %AthleteSubscribedToNotificationEmails{notification_type: notification_type}
      ) do
    %AthleteNotifications{
      athlete_notifications
      | notifications: Map.put(notifications, notification_type, true)
    }
  end

  def apply(
        %AthleteNotifications{notifications: notifications} = athlete_notifications,
        %AthleteUnsubscribedFromNotificationEmails{notification_type: notification_type}
      ) do
    %AthleteNotifications{
      athlete_notifications
      | notifications: Map.put(notifications, notification_type, false)
    }
  end

  # Private helpers

  defp toggle_subscription(
         %AthleteNotifications{
           athlete_notification_uuid: athlete_notification_uuid,
           athlete_uuid: athlete_uuid,
           notifications: notifications
         },
         notification_type
       ) do
    case Map.get(notifications, notification_type, true) do
      true ->
        %AthleteUnsubscribedFromNotificationEmails{
          athlete_notification_uuid: athlete_notification_uuid,
          athlete_uuid: athlete_uuid,
          notification_type: notification_type
        }

      false ->
        %AthleteSubscribedToNotificationEmails{
          athlete_notification_uuid: athlete_notification_uuid,
          athlete_uuid: athlete_uuid,
          notification_type: notification_type
        }
    end
  end
end
