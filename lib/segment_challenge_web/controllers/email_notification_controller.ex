defmodule SegmentChallengeWeb.EmailNotificationController do
  use SegmentChallengeWeb, :controller

  alias SegmentChallenge.Projections.EmailNotificationSettingProjection
  alias SegmentChallenge.Repo
  alias SegmentChallengeWeb.Plugs.EnsureAuthenticated

  plug(:set_active_section, :settings)
  plug(EnsureAuthenticated)

  def index(conn, _params) do
    email_notification = Repo.get(EmailNotificationSettingProjection, current_athlete_uuid(conn))

    render(conn, "index.html", email_notification: email_notification)
  end
end
