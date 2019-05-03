defmodule SegmentChallengeWeb.ToggleEmailNotificationBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Commands.ToggleEmailNotification
  alias SegmentChallenge.Notifications.AthleteNotifications

  def build(conn, params) do
    params
    |> assign_athlete_notification_uuid(conn)
    |> assign_notification_type()
    |> ToggleEmailNotification.new()
  end

  def assign_athlete_notification_uuid(params, conn) do
    athlete_notification_uuid =
      conn
      |> current_athlete_uuid()
      |> AthleteNotifications.identity()

    Map.put(params, :athlete_notification_uuid, athlete_notification_uuid)
  end

  def assign_notification_type(%{"value" => notification_type} = params) do
    Map.put(params, :notification_type, notification_type)
  end

  def assign_notification_type(params), do: params
end
