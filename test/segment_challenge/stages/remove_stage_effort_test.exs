defmodule SegmentChallenge.Stages.Stage.RemoveStageEffortsTest do
  use SegmentChallenge.StorageCase
  use SegmentChallenge.Stages.Stage.Aliases

  import SegmentChallenge.Factory
  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Router
  alias SegmentChallenge.Events.StageLeaderboardRanked

  @moduletag :integration

  describe "importing stage efforts" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :import_athlete_gender_changed,
      :import_segment_stage_efforts
    ]

    test "import stage efforts", %{
      athlete_uuid: athlete_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid
    } do
      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.athlete_uuid == athlete_uuid end,
        fn event ->
          assert event.athlete_uuid == athlete_uuid
          assert event.athlete_gender == "M"

          assert event.start_date == ~N[2016-01-25 12:48:14]
          assert event.start_date_local == ~N[2016-01-25 12:48:14]
        end
      )

      assert_receive_event(
        StageLeaderboardRanked,
        fn event ->
          Enum.any?(event.stage_efforts, fn stage_effort ->
            stage_effort.athlete_gender == "M"
          end)
        end,
        fn event ->
          assert event.stage_uuid == stage_uuid
        end
      )

      assert_receive_event(
        AthleteGenderAmendedInStage,
        fn event ->
          assert event.challenge_uuid == challenge_uuid
          assert event.stage_uuid == stage_uuid
          assert event.athlete_uuid == athlete_uuid
          assert event.gender == "F"
        end
      )

      assert_receive_event(
        StageEffortRemoved,
        fn event ->
          assert event.stage_uuid == stage_uuid
          assert event.athlete_uuid == athlete_uuid
        end
      )

      assert_receive_event(
        StageLeaderboardRanked,
        fn event -> length(event.stage_efforts) == 0 end,
        fn event ->
          assert event.stage_uuid == stage_uuid
        end
      )

      assert_receive_event(
        StageEffortRecorded,
        fn event -> event.athlete_uuid == athlete_uuid && event.athlete_gender == "F" end,
        fn event ->
          assert event.athlete_uuid == athlete_uuid
          assert event.athlete_gender == "F"

          assert event.start_date == ~N[2016-01-25 12:48:14]
          assert event.start_date_local == ~N[2016-01-25 12:48:14]
        end
      )

      assert_receive_event(
        StageLeaderboardRanked,
        fn event ->
          Enum.any?(event.stage_efforts, fn stage_effort ->
            stage_effort.athlete_gender == "F"
          end)
        end,
        fn event ->
          assert event.stage_uuid == stage_uuid
        end
      )
    end
  end

  defp import_athlete_gender_changed(%{athlete_uuid: athlete_uuid}) do
    command =
      build(:import_athlete, athlete_uuid: athlete_uuid, strava_id: 5_704_447, gender: "F")

    Router.dispatch(command)
  end
end
