defmodule SegmentChallenge.AthleteFactory do
  alias SegmentChallenge.Commands.ImportAthlete

  defmacro __using__(_opts) do
    quote do
      def athlete_factory do
        %{
          id: 5_704_447,
          firstname: "Ben",
          lastname: "Smith",
          email: "ben@segmentchallenge.com",
          city: "Winchester",
          state: "England",
          country: "United Kingdom",
          sex: "M",
          premium: true,
          profile: "https://example.com/pictures/athletes/large.jpg",
          profile_medium: "https://example.com/pictures/athletes/medium.jpg"
        }
      end

      def import_athlete_factory do
        struct(ImportAthlete, build(:athlete))
      end
    end
  end
end
