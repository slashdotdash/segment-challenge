defmodule SegmentChallenge.Authorisation.Policies.AthleteNotificationsPolicy do
  alias SegmentChallenge.Authorisation.User
  alias SegmentChallenge.Notifications.AthleteNotifications

  alias SegmentChallenge.Commands.SubscribeAthleteToAllNotifications
  alias SegmentChallenge.Commands.ToggleEmailNotification

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %SubscribeAthleteToAllNotifications{athlete_uuid: athlete_uuid} = command
      ) do
    %SubscribeAthleteToAllNotifications{athlete_notification_uuid: athlete_notification_uuid} =
      command

    athlete_notification_uuid == AthleteNotifications.identity(athlete_uuid)
  end

  def can?(%User{} = user, :dispatch, %ToggleEmailNotification{} = command) do
    %User{athlete_uuid: athlete_uuid} = user
    %ToggleEmailNotification{athlete_notification_uuid: athlete_notification_uuid} = command

    athlete_notification_uuid == AthleteNotifications.identity(athlete_uuid)
  end

  def can?(_user, _action, _command), do: false
end
