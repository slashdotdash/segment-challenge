defmodule SegmentChallenge.Projections.EmailNotificationSettingProjection do
  use Ecto.Schema

  @primary_key {:athlete_uuid, :string, []}

  schema "email_notification_settings" do
    field(:email, :string)
    field(:approve_leaderboards_notification, :boolean, default: true)
    field(:host_challenge_notification, :boolean, default: true)
    field(:lost_place_notification, :boolean, default: true)

    timestamps()
  end
end
