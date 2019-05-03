defmodule SegmentChallenge.Tasks.ImportActiveStageEffortTest do
  use SegmentChallenge.StorageCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Events.StageEffortRecorded

  @moduletag :task
  @moduletag :integration

  describe "import active segment stage efforts from Strava" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :import_active_stage_efforts
    ]

    test "should import stage efforts", %{athlete_uuid: athlete_uuid} do
      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.athlete_uuid == athlete_uuid end,
        fn event ->
          assert event.strava_segment_effort_id == 11_176_421_917
        end
      )
    end
  end

  describe "import active distance stage efforts from Strava" do
    setup [
      :create_distance_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_active_distance_stage_efforts
    ]

    test "should import stage efforts", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.strava_activity_id == 1_916_162_879 end,
        fn event ->
          # https://www.strava.com/activities/1916162879
          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: ^athlete_uuid,
            athlete_gender: athlete_gender,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            activity_type: activity_type,
            start_date: start_date,
            start_date_local: start_date_local,
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

          assert athlete_gender == "M"
          assert strava_activity_id == 1_916_162_879
          assert is_nil(strava_segment_effort_id)
          assert activity_type == "Ride"
          assert distance_in_metres == 43871.1
          assert elevation_gain_in_metres == 432.0
          assert start_date == ~N[2018-10-20 11:26:42]
          assert start_date_local == ~N[2018-10-20 12:26:42]
          assert moving_time_in_seconds == 5221
          assert is_nil(average_cadence)
          assert is_nil(average_heartrate)
          assert is_nil(max_heartrate)
          assert average_watts == 202.9
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

  describe "import active race stage efforts from Strava" do
    setup [
      :create_virtual_race_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_active_race_stage_efforts
    ]

    test "should import stage efforts", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.strava_activity_id == 2_029_711_184 end,
        fn event ->
          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: ^athlete_uuid,
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
