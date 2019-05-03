defmodule SegmentChallenge.Events.AthleteNotificationEmailChanged do
  @derive Jason.Encoder
  defstruct [
    :athlete_notification_uuid,
    :athlete_uuid,
    :email,
  ]
end
