defmodule SegmentChallenge.Leaderboards.StageLeaderboard.Projections.StageLeaderboardProjectionTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import Ecto.Query, only: [from: 2]
  import SegmentChallenge.Enumerable
  import SegmentChallenge.Factory
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Wait
  alias SegmentChallenge.Events.CompetitorParticipationInChallengeLimited
  alias SegmentChallenge.Events.StageLeaderboardCreated
  alias SegmentChallenge.Events.StageLeaderboardRanked
  alias SegmentChallenge.Router
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardEntryProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection

  @moduletag :integration
  @moduletag :projection

  describe "starting a stage" do
    setup [:create_challenge, :create_stage, :start_stage]

    test "should create a stage leaderboard projection per stage leaderboard", %{
      stage_uuid: stage_uuid
    } do
      wait_for_event(StageLeaderboardCreated, fn event -> event.stage_uuid == stage_uuid end)

      Wait.until(fn ->
        leaderboards = stage_leaderboard_query(stage_uuid) |> Repo.all()

        assert length(leaderboards) == 2
        assert Enum.sort(pluck(leaderboards, :name)) == ["Men", "Women"]
      end)
    end
  end

  describe "ranking stage efforts" do
    setup [
      :create_challenge,
      :create_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :wait_for_stage_leaderboard_ranked
    ]

    test "should record leaderboard entry", %{
      athlete_uuid: athlete_uuid,
      stage_leaderboard_uuid: stage_leaderboard_uuid
    } do
      Wait.until(fn ->
        leaderboard_entries =
          stage_leaderboard_entry_query(stage_leaderboard_uuid, athlete_uuid)
          |> Repo.all()

        assert length(leaderboard_entries) > 0

        leaderboard_entry = hd(leaderboard_entries)
        assert leaderboard_entry.elapsed_time_in_seconds == 188
        assert Float.round(leaderboard_entry.speed_in_mph, 1) == 11.2
        assert Float.round(leaderboard_entry.speed_in_kph, 1) == 17.9
        assert leaderboard_entry.strava_segment_effort_id == 11_478_431_697
        assert leaderboard_entry.athlete_point_scoring_limited == false
        assert leaderboard_entry.athlete_limit_reason == nil
      end)
    end

    test "should replace existing leaderboard entry when athlete records a quicker time",
         %{athlete_uuid: athlete_uuid, stage_leaderboard_uuid: stage_leaderboard_uuid} do
      :ok =
        dispatch(:rank_stage_efforts_in_stage_leaderboard,
          stage_leaderboard_uuid: stage_leaderboard_uuid,
          stage_efforts: [
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort),
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
              strava_activity_id: 3,
              strava_segment_effort_id: 3,
              elapsed_time_in_seconds: 170,
              moving_time_in_seconds: 170
            )
          ]
        )

      Wait.until(fn ->
        leaderboard_entries =
          stage_leaderboard_entry_query(stage_leaderboard_uuid, athlete_uuid)
          |> Repo.all()

        assert length(leaderboard_entries) > 0

        leaderboard_entry = hd(leaderboard_entries)
        assert leaderboard_entry.elapsed_time_in_seconds == 170
        assert leaderboard_entry.moving_time_in_seconds == 170
      end)
    end

    test "should update leaderboard entry rank when another competitor records a quicker time and athlete loses a position in leaderboard",
         %{athlete_uuid: athlete_uuid, stage_leaderboard_uuid: stage_leaderboard_uuid} do
      another_athlete_uuid = "athlete-#{UUID.uuid4()}"

      :ok =
        dispatch(:import_athlete,
          athlete_uuid: another_athlete_uuid,
          strava_id: 2,
          firstname: "Another",
          lastname: "Athlete",
          gender: "M"
        )

      :ok =
        dispatch(:rank_stage_efforts_in_stage_leaderboard,
          stage_leaderboard_uuid: stage_leaderboard_uuid,
          stage_efforts: [
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort),
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
              athlete_uuid: another_athlete_uuid,
              strava_activity_id: 3,
              strava_segment_effort_id: 3,
              elapsed_time_in_seconds: 165,
              moving_time_in_seconds: 165
            )
          ]
        )

      Wait.until(fn ->
        leaderboard_entries =
          stage_leaderboard_entries_query(stage_leaderboard_uuid) |> Repo.all()

        assert length(leaderboard_entries) == 2
        [first_entry, second_entry] = leaderboard_entries

        assert first_entry.rank == 1
        assert first_entry.athlete_uuid == another_athlete_uuid
        assert first_entry.elapsed_time_in_seconds == 165

        assert second_entry.rank == 2
        assert second_entry.athlete_uuid == athlete_uuid
        assert second_entry.elapsed_time_in_seconds == 188
      end)
    end

    test "should update leaderboard entry rank when athlete records another attempt that is quicker than a competitor and gains a position in leaderboard",
         %{athlete_uuid: athlete_uuid, stage_leaderboard_uuid: stage_leaderboard_uuid} do
      another_athlete_uuid = "athlete-#{UUID.uuid4()}"

      :ok =
        dispatch(:import_athlete,
          athlete_uuid: another_athlete_uuid,
          strava_id: 2,
          firstname: "Another",
          lastname: "Athlete",
          gender: "M"
        )

      # Another athlete records a slower time
      :ok =
        dispatch(:rank_stage_efforts_in_stage_leaderboard,
          stage_leaderboard_uuid: stage_leaderboard_uuid,
          stage_efforts: [
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort),
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
              athlete_uuid: another_athlete_uuid,
              strava_activity_id: 3,
              strava_segment_effort_id: 3,
              elapsed_time_in_seconds: 190,
              moving_time_in_seconds: 190
            )
          ]
        )

      # Another athlete records a faster time
      :ok =
        dispatch(:rank_stage_efforts_in_stage_leaderboard,
          stage_leaderboard_uuid: stage_leaderboard_uuid,
          stage_efforts: [
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort),
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
              athlete_uuid: another_athlete_uuid,
              strava_activity_id: 3,
              strava_segment_effort_id: 3,
              elapsed_time_in_seconds: 190,
              moving_time_in_seconds: 190
            ),
            build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
              athlete_uuid: another_athlete_uuid,
              strava_activity_id: 4,
              strava_segment_effort_id: 4,
              elapsed_time_in_seconds: 165,
              moving_time_in_seconds: 165
            )
          ]
        )

      Wait.until(fn ->
        leaderboard_entries =
          stage_leaderboard_entries_query(stage_leaderboard_uuid) |> Repo.all()

        assert length(leaderboard_entries) == 2
        [first_entry, second_entry] = leaderboard_entries

        assert first_entry.rank == 1
        assert first_entry.athlete_uuid == another_athlete_uuid
        assert first_entry.elapsed_time_in_seconds == 165

        assert second_entry.rank == 2
        assert second_entry.athlete_uuid == athlete_uuid
        assert second_entry.elapsed_time_in_seconds == 188
      end)
    end
  end

  describe "flag athlete's only stage effort" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :second_athlete_join_challenge,
      :import_one_segment_stage_effort,
      :flag_stage_effort,
      :wait_for_stage_leaderboard_ranked
    ]

    test "should remove stage effort leaderboard entry", %{
      stage_leaderboard_uuid: stage_leaderboard_uuid
    } do
      Wait.until(fn ->
        entries = stage_leaderboard_entries_query(stage_leaderboard_uuid) |> Repo.all()
        assert entries == []
      end)
    end
  end

  describe "flag athlete's faster stage effort" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :second_athlete_join_challenge,
      :import_two_segment_stage_efforts,
      :flag_stage_effort,
      :wait_for_stage_leaderboard_ranked
    ]

    test "should replace stage effort leaderboard entry with slower attempt", %{
      athlete_uuid: athlete_uuid,
      stage_leaderboard_uuid: stage_leaderboard_uuid
    } do
      Wait.until(fn ->
        assert [leaderboard_entry] =
                 stage_leaderboard_entry_query(stage_leaderboard_uuid, athlete_uuid)
                 |> Repo.all()

        assert leaderboard_entry.elapsed_time_in_seconds == 218
      end)
    end
  end

  describe "limit competitor point scoring in stage leaderboard after effort ranked" do
    setup [
      :create_challenge,
      :create_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :limit_competitor_participation,
      :wait_for_stage_leaderboard_ranked
    ]

    test "should add warning to leaderboard entry", %{
      athlete_uuid: athlete_uuid,
      stage_leaderboard_uuid: stage_leaderboard_uuid
    } do
      wait_for_event(CompetitorParticipationInChallengeLimited, fn event ->
        event.athlete_uuid == athlete_uuid
      end)

      Wait.until(fn ->
        leaderboard_entries =
          stage_leaderboard_entry_query(stage_leaderboard_uuid, athlete_uuid) |> Repo.all()

        assert length(leaderboard_entries) > 0

        leaderboard_entry = hd(leaderboard_entries)
        assert leaderboard_entry.elapsed_time_in_seconds == 188
        assert leaderboard_entry.athlete_point_scoring_limited == true
        assert leaderboard_entry.athlete_limit_reason == "Not a first claim club member"
      end)
    end
  end

  describe "limit competitor point scoring in stage leaderboard before effort ranked" do
    setup [
      :create_challenge,
      :create_stage,
      :start_stage,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :limit_competitor_participation,
      :import_segment_stage_efforts,
      :wait_for_stage_leaderboard_ranked
    ]

    test "should add warning to leaderboard entry", %{
      athlete_uuid: athlete_uuid,
      stage_leaderboard_uuid: stage_leaderboard_uuid
    } do
      Wait.until(fn ->
        leaderboard_entries =
          stage_leaderboard_entry_query(stage_leaderboard_uuid, athlete_uuid) |> Repo.all()

        assert length(leaderboard_entries) > 0

        leaderboard_entry = hd(leaderboard_entries)
        assert leaderboard_entry.elapsed_time_in_seconds == 188
        assert leaderboard_entry.athlete_point_scoring_limited == true
        assert leaderboard_entry.athlete_limit_reason == "Not a first claim club member"
      end)
    end
  end

  defp wait_for_stage_leaderboard_ranked(context) do
    %{athlete_uuid: athlete_uuid} = context

    stage_leaderboard_ranked =
      wait_for_event(StageLeaderboardRanked, fn %StageLeaderboardRanked{} = event ->
        %StageLeaderboardRanked{stage_efforts: stage_efforts} = event

        Enum.any?(stage_efforts, fn
          %StageLeaderboardRanked.StageEffort{athlete_uuid: ^athlete_uuid} -> true
          %StageLeaderboardRanked.StageEffort{} -> false
        end)
      end)

    stage_leaderboard_uuid = stage_leaderboard_ranked.data.stage_leaderboard_uuid

    [stage_leaderboard_uuid: stage_leaderboard_uuid]
  end

  def stage_leaderboard_entries_query(stage_leaderboard_uuid) do
    from(entry in StageLeaderboardEntryProjection,
      where: entry.stage_leaderboard_uuid == ^stage_leaderboard_uuid,
      order_by: [asc: entry.rank]
    )
  end

  def stage_leaderboard_entry_query(stage_leaderboard_uuid, athlete_uuid) do
    from(entry in StageLeaderboardEntryProjection,
      where:
        entry.stage_leaderboard_uuid == ^stage_leaderboard_uuid and
          entry.athlete_uuid == ^athlete_uuid,
      order_by: [asc: entry.rank]
    )
  end

  def stage_leaderboard_query(stage_uuid) do
    from(sl in StageLeaderboardProjection, where: sl.stage_uuid == ^stage_uuid)
  end

  defp dispatch(command, attrs) do
    command = build(command, attrs)

    Router.dispatch(command)
  end
end
