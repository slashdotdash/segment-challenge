defmodule SegmentChallenge.Challenges.SegmentChallenge do
  use SegmentChallenge.Challenges.Challenge.Aliases

  import SegmentChallenge.Challenges.ChallengeGuards

  alias SegmentChallenge.Challenges.Challenge

  defmacro __using__(_opts) do
    quote do
      defp request_stages(%Challenge{challenge_type: challenge_type}, _stages)
           when is_segment_challenge(challenge_type),
           do: []

      defp request_challenge_leaderboards(%Challenge{challenge_type: challenge_type} = challenge)
           when is_segment_challenge(challenge_type) do
        %Challenge{challenge_uuid: challenge_uuid} = challenge

        # Stage types: "flat", "rolling", "mountain"
        [
          %{
            name: "GC",
            description: "General classification",
            gender: "M",
            points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1]
          },
          %{
            name: "GC",
            description: "General classification",
            gender: "F",
            points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1]
          },
          %{
            name: "KOM",
            description: "King of the mountains",
            gender: "M",
            points: %{:mountain => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}
          },
          %{
            name: "QOM",
            description: "Queen of the mountains",
            gender: "F",
            points: %{:mountain => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}
          },
          %{
            name: "Sprint",
            description: "Sprint",
            gender: "M",
            points: %{:flat => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}
          },
          %{
            name: "Sprint",
            description: "Sprint",
            gender: "F",
            points: %{:flat => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}
          }
        ]
        |> Enum.map(fn %{name: name, description: description, gender: gender, points: points} ->
          %ChallengeLeaderboardRequested{
            challenge_uuid: challenge_uuid,
            challenge_type: challenge_type,
            name: name,
            description: description,
            gender: gender,
            points: points,
            rank_by: "points",
            rank_order: "desc",
            has_goal?: false
          }
        end)
      end
    end
  end
end
