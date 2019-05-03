defmodule SegmentChallenge.Factory do
  use ExMachina
  use SegmentChallenge.AthleteFactory
  use SegmentChallenge.ChallengeFactory
  use SegmentChallenge.ChallengeLeaderboardFactory
  use SegmentChallenge.StageFactory
  use SegmentChallenge.StageLeaderboardFactory

  alias SegmentChallenge.Commands.ImportClub

  def import_club_factory do
    %ImportClub{
      club_uuid: "club-7289",
      strava_id: 7289,
      name: "VC Venta",
      description:
        "Friendly cycling club in Winchester for those interested in cycling of all kinds.",
      sport_type: "cycling",
      city: "Winchester",
      state: "England",
      country: "United Kingdom",
      profile: "https://example.com/pictures/clubs/large.jpg",
      private: false
    }
  end

  def club_factory do
    %Strava.DetailedClub{
      id: 7289,
      name: "VC Venta",
      sport_type: "cycling",
      city: "Winchester",
      state: "England",
      country: "United Kingdom",
      profile_medium:
        "https://example.com/pictures/clubs/large.jpg",
      private: false
    }
  end

  def athlete_notifications_factory do
    %{
      athlete_notification_uuid: "athlete-5704447-notification",
      athlete_uuid: "athlete-5704447",
      firstname: "Ben",
      lastname: "Smith",
      email: "ben@segmentchallenge.com"
    }
  end

  def challenge_leaderboard_factory do
    %{
      name: "GC",
      description: "General classification",
      gender: "M",
      points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1]
    }
  end

  def strava_segment_factory do
    %{
      id: 8_622_812,
      activity_type: "Ride",
      athlete_count: 426,
      average_grade: 7.5,
      city: "Winchester",
      state: "Hampshire",
      climb_category: 0,
      country: "United Kingdom",
      distance: 908.2,
      effort_count: 3923,
      elevation_high: 124.5,
      elevation_low: 56.5,
      end_latlng: [51.058537, -1.339321],
      hazardous: false,
      map: %{
        id: "s229781",
        polyline: "aasvHffbG[hDAp@J`Bh@lDR`Bb@vKC|Bo@rE[hBmA|GeAnF{@pDcAvDc@vA",
        resource_state: 3
      },
      maximum_grade: 11.7,
      name: "VCV Sleepers Hill",
      private: false,
      resource_state: 2,
      star_count: 13,
      starred: true,
      start_latlng: [51.056973, -1.327232],
      total_elevation_gain: 68.0
    }
  end

  def strava_stage_effort_factory do
    %{
      id: 11_080_757_624,
      activity: %{id: 460_619_610, resource_state: 1},
      athlete: %{id: 5_704_447, resource_state: 1},
      average_cadence: 70.2,
      average_heartrate: nil,
      average_watts: 332.9,
      device_watts: false,
      distance: 911.2,
      elapsed_time: 172,
      end_index: 1679,
      hidden: nil,
      kom_rank: nil,
      max_heartrate: nil,
      moving_time: 172,
      name: "VCV Sleepers Hill",
      pr_rank: nil,
      resource_state: 2,
      segment: %{
        id: 8_622_812,
        activity_type: "Ride",
        average_grade: 7.5,
        city: "Winchester",
        climb_category: 0,
        country: "United Kingdom",
        distance: 908.2,
        elevation_high: 124.5,
        elevation_low: 56.5,
        end_latitude: 51.058537,
        end_latlng: [51.058537, -1.339321],
        end_longitude: -1.339321,
        hazardous: false,
        maximum_grade: 11.7,
        name: "VCV Sleepers Hill",
        private: false,
        resource_state: 2,
        starred: true,
        start_latitude: 51.056973,
        start_latlng: [51.056973, -1.327232],
        start_longitude: -1.327232,
        state: nil
      },
      start_date: ~N[2016-01-01 11:42:21],
      start_date_local: ~N[2016-01-01 11:42:21],
      start_index: 1593
    }
  end
end
