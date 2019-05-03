defmodule SegmentChallenge.Commands.ToggleEmailNotification do
  defstruct [
    :athlete_notification_uuid,
    :notification_type,
  ]

  use ExConstructor
  use Vex.Struct

  validates :athlete_notification_uuid, uuid: true
  validates :notification_type, string: true, presence: true
end
