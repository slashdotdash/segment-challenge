defmodule SegmentChallenge.Stages.Stage.ImportStageEffortsTest do
  use SegmentChallenge.StorageCase
  use SegmentChallenge.Stages.Stage.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  @moduletag :integration

  describe "importing segment stage efforts" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts
    ]

    test "should record stage efforts", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.strava_activity_id == 478_127_401 end,
        fn event ->
          # https://www.strava.com/activities/478127401/segments/11478431697
          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: athlete_uuid,
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

          assert athlete_uuid == "athlete-5704447"
          assert athlete_gender == "M"
          assert strava_activity_id == 478_127_401
          assert strava_segment_effort_id == 11_478_431_697
          assert activity_type == "Ride"
          assert distance_in_metres == 937.3
          assert elevation_gain_in_metres == 68.0
          assert start_date == ~N[2016-01-25 12:48:14]
          assert start_date_local == ~N[2016-01-25 12:48:14]
          assert moving_time_in_seconds == 188
          assert average_cadence == 94.3
          assert is_nil(average_heartrate)
          assert is_nil(max_heartrate)
          assert average_watts == 352.0
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

  describe "importing another segment stage effort" do
    setup [
      :create_challenge,
      :create_segment_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :import_another_segment_stage_effort
    ]

    test "should record new stage effort", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.strava_activity_id == 481_664_864 end,
        fn event ->
          # https://www.strava.com/activities/481664864/segments/11557296753
          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: athlete_uuid,
            athlete_gender: athlete_gender,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            activity_type: activity_type,
            start_date: start_date,
            start_date_local: start_date_local,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
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
          assert strava_activity_id == 481_664_864
          assert strava_segment_effort_id == 11_557_296_753
          assert activity_type == "Ride"
          assert distance_in_metres == 936.2
          assert elevation_gain_in_metres == 68.0
          assert start_date == ~N[2016-01-30 11:14:24]
          assert start_date_local == ~N[2016-01-30 11:14:24]
          assert elapsed_time_in_seconds == 249
          assert moving_time_in_seconds == 211
          assert average_cadence == 88.3
          assert is_nil(average_heartrate)
          assert is_nil(max_heartrate)
          assert average_watts == 302.0
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

  describe "importing distance stage efforts" do
    setup [
      :create_distance_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_distance_stage_efforts
    ]

    test "import stage efforts", %{stage_uuid: stage_uuid} do
      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.athlete_uuid == "athlete-5704447" end,
        fn event ->
          # https://www.strava.com/activities/1916162879

          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: athlete_uuid,
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

          assert athlete_uuid == "athlete-5704447"
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

  describe "importing race stage efforts" do
    setup [
      :create_virtual_race_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge
    ]

    test "should be imported", %{stage_uuid: stage_uuid} = context do
      :ok = import_race_stage_efforts(context)

      assert_receive_event(
        StageEffortRecorded,
        fn event ->
          event.strava_activity_id == 2_036_038_630 and
            event.strava_segment_effort_id == 4_351_445_437
        end,
        fn event ->
          # https://www.strava.com/activities/2029711184
          %StageEffortRecorded{
            stage_uuid: ^stage_uuid,
            athlete_uuid: athlete_uuid,
            athlete_gender: athlete_gender,
            strava_activity_id: 2_036_038_630,
            strava_segment_effort_id: 4_351_445_437,
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
          assert activity_type == "Run"
          assert distance_in_metres == 5000.0
          assert is_nil(elevation_gain_in_metres)
          assert start_date == ~N[2018-12-26 11:00:33]
          assert start_date_local == ~N[2018-12-26 11:00:33]
          assert elapsed_time_in_seconds == 1377
          assert moving_time_in_seconds == 1365
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

    test "should not import activity less than race distance", context do
      refute_receive_event(StageEffortRecorded,
        predicate: fn event -> event.strava_activity_id == 2_041_519_332 end
      ) do
        :ok = import_race_stage_efforts(context)
      end
    end
  end
end
