defmodule SegmentChallengeWeb.ActivityView do
  use SegmentChallengeWeb, :view

  import SegmentChallengeWeb.Helpers.ActivityHelpers

  alias Phoenix.HTML.Link
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection
  alias SegmentChallenge.Repo.Page

  def activity_feed_next_page_link(%Page{} = page) do
    %Page{page_number: page_number} = page

    """
    <a href="?page=#{page_number + 1}" class="button is-medium">More &hellip;</a>
    """
    |> raw()
  end

  defp link_to_activity_actor(conn, %ActivityProjection{} = activity) do
    %ActivityProjection{actor_type: actor_type, actor_name: actor_name, actor_uuid: actor_uuid} =
      activity

    case actor_type do
      "athlete" -> Link.link(actor_name, to: strava_athlete_url(actor_uuid), target: "_blank")
      "challenge" -> Link.link(actor_name, to: redirect_path(conn, :challenge, actor_uuid))
      "stage" -> Link.link(actor_name, to: redirect_path(conn, :stage, actor_uuid))
      _actor_type -> actor_name
    end
  end
end
