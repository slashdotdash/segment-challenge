defmodule SegmentChallengeWeb.SubscribeAthleteToAllNotificationsBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Commands.SubscribeAthleteToAllNotifications
  alias SegmentChallenge.Notifications.AthleteNotifications

  def build(conn, params) do
    params
    |> assign_athlete_uuid(conn)
    |> assign_athlete_notification_uuid(conn)
    |> SubscribeAthleteToAllNotifications.new()
  end

  def assign_athlete_notification_uuid(params, conn) do
    athlete_notification_uuid =
      conn
      |> current_athlete_uuid()
      |> AthleteNotifications.identity()

    Map.put(params, :athlete_notification_uuid, athlete_notification_uuid)
  end
end
