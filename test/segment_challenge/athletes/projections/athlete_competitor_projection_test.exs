defmodule SegmentChallenge.Projections.AthleteCompetitorProjectionTest do
  use SegmentChallenge.StorageCase

  import SegmentChallenge.UseCases.ImportAthleteUseCase

  alias SegmentChallenge.Wait
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Projections.AthleteCompetitorProjection

  describe "importing an athlete" do
    setup [
      :import_athlete
    ]

    @tag :integration
    @tag :projection
    test "should create athlete competitor", context do
      Wait.until(fn ->
        assert Repo.get(AthleteCompetitorProjection, context[:athlete_uuid]) != nil
      end)
    end
  end

  describe "importing an existing athlete with changed details" do
    setup [
      :import_athlete,
      :import_athlete_with_changed_details
    ]

    @tag :integration
    @tag :projection
    test "should update athlete competitor's name, email, and profile", context do
      Wait.until(fn ->
        athlete_competitor = Repo.get(AthleteCompetitorProjection, context[:athlete_uuid])

        assert athlete_competitor != nil
        assert athlete_competitor.firstname == "Changed"
        assert athlete_competitor.lastname == "Athlete"
        assert athlete_competitor.email == "changed@segmentchallenge.com"
        assert athlete_competitor.profile == "http://example.com/updated.jpg"
      end)
    end
  end

  defp import_athlete_with_changed_details(context) do
    import_athlete_using(
      firstname: "Changed",
      lastname: "Athlete",
      email: "changed@segmentchallenge.com",
      profile: "http://example.com/updated.jpg"
    )

    context
  end
end
