defmodule SegmentChallenge.Notifications do
  alias SegmentChallenge.Projections.EmailNotificationSettingProjection
  alias SegmentChallenge.Repo

  @doc """
  Is the given athlete subscribed to the notification type
  """
  def subscribed?(athlete_uuid, type) do
    case notification(athlete_uuid) do
      nil -> false
      notification -> Map.get(notification, type, false)
    end
  end

  def email(athlete_uuid) do
    Repo.get!(EmailNotificationSettingProjection, athlete_uuid).email
  end

  defp notification(athlete_uuid) do
    Repo.get(EmailNotificationSettingProjection, athlete_uuid)
  end
end
