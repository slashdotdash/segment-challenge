defmodule SegmentChallengeWeb.API.AthleteView do
  use SegmentChallengeWeb, :view

  alias SegmentChallenge.Projections.Clubs.ClubProjection

  def render("clubs.json", %{clubs: clubs}) do
    Enum.map(clubs, &to_json/1)
  end

  def render("starred_segments.json", %{starred_segments: starred_segments}) do
    starred_segments
    |> Enum.reject(fn %Strava.SummarySegment{private: private} -> private end)
    |> Enum.map(&to_json/1)
  end

  defp to_json(%ClubProjection{} = club) do
    %ClubProjection{
      club_uuid: club_uuid,
      name: name,
      description: description,
      city: city,
      state: state,
      country: country,
      profile: profile
    } = club

    %{
      club_uuid: club_uuid,
      name: name,
      description: description,
      city: city,
      state: state,
      country: country,
      profile: profile
    }
  end

  defp to_json(%Strava.SummaryClub{} = club) do
    %Strava.SummaryClub{
      id: id,
      name: name,
      city: city,
      state: state,
      country: country,
      profile_medium: profile
    } = club

    %{
      club_uuid: "club-#{id}",
      name: name,
      description: "",
      city: city,
      state: state,
      country: country,
      profile: profile
    }
  end

  defp to_json(%Strava.SummarySegment{} = segment) do
    %Strava.SummarySegment{
      id: strava_segment_id,
      name: name,
      activity_type: activity_type,
      distance: distance_in_metres,
      average_grade: average_grade,
      maximum_grade: maximum_grade,
      climb_category: climb_category,
      city: city,
      state: state,
      country: country
    } = segment

    %{
      strava_segment_id: strava_segment_id,
      name: name,
      activity_type: activity_type,
      distance_in_metres: round(distance_in_metres),
      average_grade: round(average_grade, 1),
      maximum_grade: round(maximum_grade, 1),
      climb_category: climb_category,
      city: city,
      state: state,
      country: country
    }
  end
end
