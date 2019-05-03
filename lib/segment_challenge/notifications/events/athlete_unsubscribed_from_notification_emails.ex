defmodule SegmentChallenge.Events.AthleteUnsubscribedFromNotificationEmails do
  @derive Jason.Encoder
  defstruct [
    :athlete_notification_uuid,
    :athlete_uuid,
    :notification_type,
  ]
end
