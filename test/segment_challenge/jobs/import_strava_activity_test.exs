defmodule SegmentChallenge.Jobs.ImportStravaActivityTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Events.StageEffortRecorded

  @moduletag :task
  @moduletag :integration

  describe "import Strava activity for segment stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge
    ]

    test "should import stage effort", %{athlete_uuid: athlete_uuid} do
      # https://www.strava.com/activities/465157631
      :ok = import_strava_activity(465_157_631)

      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.strava_activity_id == 465_157_631 end,
        fn event ->
          assert event.athlete_uuid == athlete_uuid
          assert event.strava_segment_effort_id == 11_176_421_917
        end
      )
    end
  end

  describe "import Strava activity for distance stage" do
    setup [
      :create_distance_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge
    ]

    test "should import stage effort", %{stage_uuid: stage_uuid} do
      # https://www.strava.com/activities/1936443168
      :ok = import_strava_activity(1_936_443_168)

      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.strava_activity_id == 1_936_443_168 end,
        fn event ->
          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: athlete_uuid,
            athlete_gender: athlete_gender,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            activity_type: activity_type,
            start_date: start_date,
            start_date_local: start_date_local,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            moving_time_in_seconds: moving_time_in_seconds,
            average_cadence: average_cadence,
            average_heartrate: average_heartrate,
            average_watts: average_watts,
            commute?: commute?,
            private?: private?,
            flagged?: flagged?,
            manual?: manual?,
            trainer?: trainer?,
            device_watts?: device_watts?,
            max_heartrate: max_heartrate
          } = event

          assert athlete_uuid == "athlete-5704447"
          assert athlete_gender == "M"
          assert strava_activity_id == 1_936_443_168
          assert is_nil(strava_segment_effort_id)
          assert activity_type == "Ride"
          assert elapsed_time_in_seconds == 6096
          assert distance_in_metres == 50472.7
          assert elevation_gain_in_metres == 487.0
          assert start_date == ~N[2018-10-30 18:51:34]
          assert start_date_local == ~N[2018-10-30 18:51:34]
          assert moving_time_in_seconds == 5642
          assert is_nil(average_cadence)
          assert is_nil(average_heartrate)
          assert is_nil(max_heartrate)
          assert average_watts == 176.7
          refute commute?
          refute manual?
          refute private?
          refute flagged?
          assert device_watts?
          refute trainer?
        end
      )
    end
  end

  describe "import Strava activity for race stage" do
    setup [
      :create_virtual_race_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge
    ]

    test "should import best effort for race distance", %{stage_uuid: stage_uuid} do
      # https://www.strava.com/activities/2029711184
      :ok = import_strava_activity(2_029_711_184)

      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.strava_activity_id == 2_029_711_184 end,
        fn event ->
          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: athlete_uuid,
            athlete_gender: athlete_gender,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            activity_type: activity_type,
            start_date: start_date,
            start_date_local: start_date_local,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            moving_time_in_seconds: moving_time_in_seconds,
            average_cadence: average_cadence,
            average_heartrate: average_heartrate,
            average_watts: average_watts,
            commute?: commute?,
            private?: private?,
            flagged?: flagged?,
            manual?: manual?,
            trainer?: trainer?,
            device_watts?: device_watts?,
            max_heartrate: max_heartrate
          } = event

          assert athlete_uuid == "athlete-5704447"
          assert athlete_gender == "M"
          assert strava_activity_id == 2_029_711_184
          assert strava_segment_effort_id == 4_336_058_562
          assert activity_type == "Run"
          assert distance_in_metres == 5000.0
          assert is_nil(elevation_gain_in_metres)
          assert start_date == ~N[2018-12-22 12:23:39]
          assert start_date_local == ~N[2018-12-22 12:23:39]
          assert elapsed_time_in_seconds == 1577
          assert moving_time_in_seconds == 1570
          assert is_nil(average_cadence)
          assert is_nil(average_heartrate)
          assert is_nil(max_heartrate)
          assert is_nil(average_watts)
          refute commute?
          refute manual?
          refute private?
          refute flagged?
          refute device_watts?
          refute trainer?
        end
      )
    end
  end
end
