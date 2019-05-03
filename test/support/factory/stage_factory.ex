defmodule SegmentChallenge.StageFactory do
  use SegmentChallenge.Stages.Stage.Aliases

  alias SegmentChallenge.StageFactory

  defmacro __using__(_opts) do
    quote do
      @stage_uuid UUID.uuid4()
      @challenge_uuid UUID.uuid4()

      def stage_factory do
        %{
          stage_number: 1,
          strava_segment_id: 8_622_812,
          name: "VCV Sleepers Hill",
          description: "The popular Sleepers Hill. Ouch!",
          stage_type: "mountain",
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-01-31 23:59:59],
          end_date_local: ~N[2016-01-31 23:59:59],
          start_description: "Start at the bottom of Sleepers Hill",
          end_description: "Finish as the top of the hill",
          distance_in_metres: 908.2,
          created_by_athlete_uuid: "athlete-5704447",
          url_slug: "vcv-sleepers-hill",
          slugger: &StageFactory.slugify/3
        }
      end

      def create_segment_stage_factory do
        %CreateSegmentStage{
          stage_uuid: @stage_uuid,
          challenge_uuid: @challenge_uuid,
          strava_segment_id: 8_622_812,
          stage_number: 1,
          stage_type: "mountain",
          name: "VCV Sleepers Hill",
          description: "The popular Sleepers Hill. Ouch!",
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-01-31 23:59:59],
          end_date_local: ~N[2016-01-31 23:59:59],
          allow_private_activities: false,
          start_description: "Start at the bottom of Sleepers Hill",
          end_description: "Finish as the top of the hill",
          created_by_athlete_uuid: "athlete-5704447",
          slugger: &StageFactory.slugify/3,
          strava_segment_factory: &strava_segment_factory/1
        }
      end

      def create_distance_stage_factory do
        %CreateActivityStage{
          stage_uuid: @stage_uuid,
          challenge_uuid: @challenge_uuid,
          stage_number: 1,
          stage_type: "distance",
          name: "December Cycling Distance Challenge",
          description: "Can you ride 1,000 miles in October 2018?",
          start_date: ~N[2018-10-01 01:00:00],
          start_date_local: ~N[2018-10-01 00:00:00],
          end_date: ~N[2018-10-31 23:59:59],
          end_date_local: ~N[2018-10-31 23:59:59],
          allow_private_activities: false,
          included_activity_types: ["Ride"],
          accumulate_activities: false,
          has_goal: true,
          goal: 1_000.0,
          goal_units: "miles",
          created_by_athlete_uuid: "athlete-5704447",
          slugger: &StageFactory.slugify/3
        }
      end

      def stage_created_factory do
        %StageCreated{
          stage_uuid: @stage_uuid,
          challenge_uuid: @challenge_uuid,
          stage_type: "mountain",
          stage_number: 1,
          name: "VCV Sleepers Hill",
          description: "The popular Sleepers Hill. Ouch!",
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-01-31 23:59:59],
          end_date_local: ~N[2016-01-31 23:59:59],
          allow_private_activities?: false,
          included_activity_types: ["Ride"],
          created_by_athlete_uuid: "athlete-5704447",
          url_slug: "vcv-sleepers-hill"
        }
      end

      def stage_goal_configured_factory do
        %StageGoalConfigured{
          stage_uuid: @stage_uuid,
          goal: 1_000.0,
          goal_measure: "distance_in_metres",
          goal_units: "miles"
        }
      end

      def set_segment_details_factory do
        struct(SetStageSegmentDetails, build(:strava_segment))
      end

      def stage_segment_configured_factory do
        %StageSegmentConfigured{
          stage_uuid: @stage_uuid,
          strava_segment_id: 8_622_812,
          start_description: "Start at the bottom of Sleepers Hill",
          end_description: "Finish as the top of the hill",
          distance_in_metres: 908.2,
          average_grade: 7.5,
          maximum_grade: 11.7,
          elevation_high: 124.5,
          elevation_low: 56.5,
          start_latlng: [51.056973, -1.327232],
          end_latlng: [51.058537, -1.339321],
          climb_category: 0,
          city: "Winchester",
          state: "Hampshire",
          country: "United Kingdom",
          total_elevation_gain: 68.0,
          map_polyline: "aasvHffbG[hDAp@J`Bh@lDR`Bb@vKC|Bo@rE[hBmA|GeAnF{@pDcAvDc@vA"
        }
      end

      def start_stage_factory do
        %StartStage{stage_uuid: @stage_uuid}
      end

      def stage_started_factory do
        %StageStarted{
          stage_uuid: @stage_uuid,
          challenge_uuid: @challenge_uuid,
          stage_number: 1,
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00]
        }
      end

      def stage_leaderboard_requested_factory do
        %StageLeaderboardRequested{
          stage_uuid: @stage_uuid,
          challenge_uuid: @challenge_uuid,
          name: "Men",
          gender: "M",
          stage_type: "mountain"
        }
      end

      def include_competitors_in_stage_factory do
        %IncludeCompetitorsInStage{
          stage_uuid: @stage_uuid,
          competitors: [
            %IncludeCompetitorsInStage.Competitor{
              athlete_uuid: "athlete-5704447",
              gender: "M"
            }
          ]
        }
      end

      def competitors_joined_stage_factory do
        %CompetitorsJoinedStage{
          stage_uuid: @stage_uuid,
          competitors: [
            %CompetitorsJoinedStage.Competitor{
              athlete_uuid: "athlete-5704447",
              gender: "M"
            }
          ]
        }
      end

      def import_stage_efforts_factory do
        %ImportStageEfforts{
          stage_uuid: @stage_uuid,
          stage_efforts: [
            build(:import_stage_efforts_stage_effort)
          ]
        }
      end

      def import_stage_efforts_stage_effort_factory do
        %ImportStageEfforts.StageEffort{
          athlete_uuid: "athlete-5704447",
          strava_activity_id: 478_127_401,
          strava_segment_effort_id: 11_478_431_697,
          activity_type: "Ride",
          elapsed_time_in_seconds: 188,
          moving_time_in_seconds: 188,
          start_date: ~N[2016-01-25 12:48:14],
          start_date_local: ~N[2016-01-25 12:48:14],
          distance_in_metres: 937.3,
          elevation_gain_in_metres: 68.0,
          commute?: false,
          trainer?: false,
          manual?: false,
          private?: false,
          flagged?: false,
          average_cadence: 94.3,
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil
        }
      end

      def stage_effort_recorded_factory do
        %StageEffortRecorded{
          stage_uuid: @stage_uuid,
          stage_type: "mountain",
          athlete_uuid: "athlete-5704447",
          athlete_gender: "M",
          strava_activity_id: 478_127_401,
          strava_segment_effort_id: 11_478_431_697,
          activity_type: "Ride",
          elapsed_time_in_seconds: 188,
          moving_time_in_seconds: 188,
          start_date: ~N[2016-01-25 12:48:14],
          start_date_local: ~N[2016-01-25 12:48:14],
          distance_in_metres: 937.3,
          elevation_gain_in_metres: 68.0,
          commute?: false,
          trainer?: false,
          manual?: false,
          private?: false,
          flagged?: false,
          average_cadence: 94.3,
          average_watts: 352.0,
          device_watts?: true,
          average_heartrate: nil,
          max_heartrate: nil,
          attempt_count: 1,
          competitor_count: 1
        }
      end

      def flag_stage_effort_factory do
        %FlagStageEffort{
          stage_uuid: @stage_uuid,
          strava_activity_id: 465_157_631,
          strava_segment_effort_id: 11_176_421_917,
          reason: "Group ride",
          flagged_by_athlete_uuid: "athlete-5704447"
        }
      end

      def stage_effort_removed_factory do
        %StageEffortRemoved{
          stage_uuid: @stage_uuid,
          strava_activity_id: 478_127_401,
          strava_segment_effort_id: 11_478_431_697,
          athlete_uuid: "athlete-5704447",
          elapsed_time_in_seconds: 188,
          moving_time_in_seconds: 188,
          distance_in_metres: 937.3,
          elevation_gain_in_metres: 68.0,
          start_date: ~N[2016-01-25 12:48:14],
          start_date_local: ~N[2016-01-25 12:48:14],
          attempt_count: 0,
          competitor_count: 0
        }
      end

      def remove_competitor_from_stage_factory do
        %RemoveCompetitorFromStage{
          stage_uuid: @stage_uuid,
          athlete_uuid: "athlete-5704447"
        }
      end

      def competitor_removed_from_stage_factory do
        %CompetitorRemovedFromStage{
          stage_uuid: @stage_uuid,
          athlete_uuid: "athlete-5704447",
          attempt_count: 1,
          competitor_count: 0
        }
      end

      def configure_athlete_gender_in_stage_factory do
        %ConfigureAthleteGenderInStage{
          stage_uuid: @stage_uuid,
          athlete_uuid: "athlete-5704447",
          gender: "M"
        }
      end

      def athlete_gender_amended_in_stage_factory do
        %AthleteGenderAmendedInStage{
          stage_uuid: @stage_uuid,
          challenge_uuid: @challenge_uuid,
          athlete_uuid: "athlete-5704447",
          gender: "M"
        }
      end

      def remove_stage_activity_factory do
        %RemoveStageActivity{
          stage_uuid: @stage_uuid,
          strava_activity_id: 478_127_401
        }
      end

      defp strava_segment_factory(_command) do
        segment = %CreateSegmentStage.Segment{
          strava_segment_id: 8_622_812,
          activity_type: "Ride",
          distance_in_metres: 908.2,
          average_grade: 7.5,
          maximum_grade: 11.7,
          elevation_high: 124.5,
          elevation_low: 56.5,
          start_latlng: [51.056973, -1.327232],
          end_latlng: [51.058537, -1.339321],
          climb_category: 0,
          city: "Winchester",
          state: "Hampshire",
          country: "United Kingdom",
          total_elevation_gain: 68.0,
          map_polyline: "aasvHffbG[hDAp@J`Bh@lDR`Bb@vKC|Bo@rE[hBmA|GeAnF{@pDcAvDc@vA"
        }

        {:ok, segment}
      end
    end
  end

  def slugify(_context, _source_uuid, name),
    do: {:ok, Slugger.slugify_downcase(name)}
end
