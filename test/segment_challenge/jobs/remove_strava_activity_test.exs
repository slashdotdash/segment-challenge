defmodule SegmentChallenge.Jobs.RemoveStravaActivityTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Events.StageEffortRemoved

  @moduletag :task
  @moduletag :integration

  describe "remove Strava activity from segment stage" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge
    ]

    test "should remove imported stage effort", %{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid
    } do
      # https://www.strava.com/activities/465157631
      :ok = import_strava_activity(465_157_631)
      :ok = remove_strava_activity(465_157_631, ~N[2016-01-01 00:01:00])

      assert_receive_event(
        StageEffortRemoved,
        fn event -> event.strava_activity_id == 465_157_631 end,
        fn event ->
          %StageEffortRemoved{
            stage_uuid: ^stage_uuid,
            athlete_uuid: ^athlete_uuid,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            attempt_count: attempt_count,
            competitor_count: competitor_count
          } = event

          assert strava_activity_id == 465_157_631
          assert strava_segment_effort_id == 11_176_421_917
          assert attempt_count == 0
          assert competitor_count == 0
        end
      )
    end
  end

  describe "remove Strava activity from distance stage" do
    setup [
      :create_distance_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge
    ]

    test "should removed imported stage effort", %{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid
    } do
      # https://www.strava.com/activities/1936443168
      :ok = import_strava_activity(1_936_443_168)
      :ok = remove_strava_activity(1_936_443_168, ~N[2018-10-01 00:01:00])

      assert_receive_event(
        StageEffortRemoved,
        fn event -> event.strava_activity_id == 1_936_443_168 end,
        fn event ->
          %StageEffortRemoved{
            stage_uuid: ^stage_uuid,
            athlete_uuid: ^athlete_uuid,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            moving_time_in_seconds: moving_time_in_seconds,
            attempt_count: attempt_count,
            competitor_count: competitor_count
          } = event

          assert strava_activity_id == 1_936_443_168
          assert is_nil(strava_segment_effort_id)
          assert elapsed_time_in_seconds == 6096
          assert distance_in_metres == 50472.7
          assert elevation_gain_in_metres == 487.0
          assert moving_time_in_seconds == 5642
          assert attempt_count == 0
          assert competitor_count == 0
        end
      )
    end
  end

  describe "remove Strava activity from race stage" do
    setup [
      :create_virtual_race_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge
    ]

    test "should import best effort for race distance", %{
      athlete_uuid: athlete_uuid,
      stage_uuid: stage_uuid
    } do
      # https://www.strava.com/activities/2029711184
      :ok = import_strava_activity(2_029_711_184)
      :ok = remove_strava_activity(2_029_711_184, ~N[2018-12-01 00:01:00])

      assert_receive_event(
        StageEffortRemoved,
        fn event -> event.strava_activity_id == 2_029_711_184 end,
        fn event ->
          %StageEffortRemoved{
            stage_uuid: ^stage_uuid,
            athlete_uuid: ^athlete_uuid,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            moving_time_in_seconds: moving_time_in_seconds,
            attempt_count: attempt_count,
            competitor_count: competitor_count
          } = event

          assert strava_activity_id == 2_029_711_184
          assert strava_segment_effort_id == 4_336_058_562
          assert elapsed_time_in_seconds == 1577
          assert moving_time_in_seconds == 1570
          assert distance_in_metres == 5000.0
          assert is_nil(elevation_gain_in_metres)
          assert attempt_count == 0
          assert competitor_count == 0
        end
      )
    end
  end
end
