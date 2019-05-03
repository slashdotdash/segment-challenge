defmodule SegmentChallenge.Commands.UpdateAthleteNotificationEmail do
  defstruct [
    :athlete_notification_uuid,
    :athlete_uuid,
    :email,
  ]

  use Vex.Struct

  validates :athlete_notification_uuid, uuid: true
  validates :athlete_uuid, uuid: true
  validates :email, presence: true, string: true
end
