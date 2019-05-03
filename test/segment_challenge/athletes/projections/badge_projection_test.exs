defmodule SegmentChallenge.Athletes.Projections.BadgeProjectionTest do
  use SegmentChallenge.StorageCase

  import Ecto.Query
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase

  alias SegmentChallenge.Athletes.Projections.BadgeProjection
  alias SegmentChallenge.{Repo, Wait}

  @moduletag :integration
  @moduletag :projection

  describe "athlete achieve challenge goal" do
    setup [
      :create_distance_challenge_with_short_goal,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_distance_stage_efforts,
      :end_stage
    ]

    test "should create starred segment projections", %{athlete_uuid: athlete_uuid} do
      Wait.until(fn ->
        assert [
                 %BadgeProjection{
                   challenge_name: "October Cycling Distance Challenge",
                   hosted_by_club_name: "VC Venta",
                   goal: 1.0,
                   goal_units: "miles",
                   single_activity_goal: false
                 }
               ] = athlete_badges_query(athlete_uuid) |> Repo.all()
      end)
    end
  end

  defp athlete_badges_query(athlete_uuid) do
    from(b in BadgeProjection, where: b.athlete_uuid == ^athlete_uuid)
  end
end
