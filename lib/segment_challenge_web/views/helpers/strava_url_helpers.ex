defmodule SegmentChallengeWeb.Helpers.StravaUrlHelpers do
  def strava_activity_url(activity_id, segment_effort_id \\ nil)

  def strava_activity_url(activity_id, nil) do
    "https://www.strava.com/activities/#{activity_id}"
  end

  def strava_activity_url(activity_id, segment_effort_id) do
    "https://www.strava.com/activities/#{activity_id}##{segment_effort_id}"
  end

  def strava_athlete_url("athlete-" <> strava_athlete_id) do
    "https://www.strava.com/athletes/#{strava_athlete_id}"
  end

  def strava_club_url("club-" <> club_id) do
    "https://www.strava.com/clubs/#{club_id}"
  end

  def strava_club_url(club_id) do
    "https://www.strava.com/clubs/#{club_id}"
  end

  def strava_segment_effort_url(segment_effort_id) do
    "https://www.strava.com/segment_efforts/#{segment_effort_id}"
  end

  def strava_segment_url(segment_id) do
    "https://www.strava.com/segments/#{segment_id}"
  end
end
