defmodule SegmentChallenge.Commands.SubscribeAthleteToAllNotifications do
  defstruct [
    :athlete_notification_uuid,
    :athlete_uuid,
    :email
  ]

  use ExConstructor
  use Vex.Struct

  validates(:athlete_notification_uuid, uuid: true)
  validates(:athlete_uuid, uuid: true)
  validates(:email, presence: true, email: true)
end
