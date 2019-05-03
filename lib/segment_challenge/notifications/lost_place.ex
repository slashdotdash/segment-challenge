defmodule SegmentChallenge.Notifications.LostPlace do
  import Ecto.Query

  alias SegmentChallenge.Notifications.LostPlace
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Projections.StageLeaderboardRankingProjection
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Events.StageLeaderboardRanked
  alias SegmentChallenge.Events.StageLeaderboardRanked.Ranking
  alias SegmentChallenge.Repo

  defstruct [
    :athlete_uuid,
    :occurred_at,
    :title,
    :taken_by_athlete,
    :leaderboard,
    :previous_rank,
    :current_rank,
    :challenge,
    :stage
  ]

  use ExConstructor

  @doc """
  Build a list of `%LostPlace{}` structs of athlete notifications.

  ## Example

      %LostPlace{
        athlete_uuid: "athlete-123456"
        occurred_at: ~N[2017-05-10 12:02:00],
        previous_rank: 3,
        current_rank: 4,
        taken_by_athlete: %{
          athlete_uuid: "athlete-7890123"
          firstname: "Ben",
          lastname: "Smith",
          time_gap_in_seconds: 10,
        },
        leaderboard: %{
          name: "Men",
          gender: "M",
        },
        challenge: %{
          url_slug: "vc-venta-segment-of-the-month",
        }
        stage: %{
          name: "VCV Wherwell Hill",
          stage_number: 3,
          end_date: ~N[2017-05-31 23:59:59],
          url_slug: "vcv-wherwell-hill",
        },
      }

  """
  def from_stage_leaderboard_ranked(%StageLeaderboardRanked{} = event, occurred_at) do
    %StageLeaderboardRanked{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      stage_uuid: stage_uuid,
      positions_lost: positions_lost
    } = event

    with %StageProjection{challenge_uuid: challenge_uuid} = stage <-
           Repo.get(StageProjection, stage_uuid),
         %ChallengeProjection{} = challenge <- Repo.get(ChallengeProjection, challenge_uuid),
         %StageLeaderboardProjection{} = leaderboard <-
           Repo.get(StageLeaderboardProjection, stage_leaderboard_uuid),
         true <- send_lost_place_notification?(stage) do
      positions_lost
      |> Enum.with_index(1)
      |> Enum.map(fn {ranking, index} ->
        lost_place(event, occurred_at, challenge, stage, leaderboard, ranking, index)
      end)
      |> Enum.filter(&was_point_scoring_place?/1)
    else
      _ -> []
    end
  end

  # Only send lost place notification for segment stages
  defp send_lost_place_notification?(%StageProjection{stage_type: stage_type})
       when stage_type in ["flat", "mountain", "rolling"],
       do: true

  defp send_lost_place_notification?(%StageProjection{}), do: false

  def merge(
        %LostPlace{previous_rank: previous_rank, occurred_at: occurred_at},
        %LostPlace{} = latest
      ) do
    %LostPlace{
      latest
      | taken_by_athlete: nil,
        occurred_at: occurred_at,
        previous_rank: previous_rank
    }
  end

  defp lost_place(
         %StageLeaderboardRanked{} = stage_leaderboard_ranked,
         occurred_at,
         %ChallengeProjection{} = challenge,
         %StageProjection{} = stage,
         %StageLeaderboardProjection{} = leaderboard,
         %Ranking{
           athlete_uuid: athlete_uuid,
           rank: current_rank,
           positions_changed: positions_changed
         },
         index
       ) do
    previous_rank = current_rank - positions_changed

    %LostPlace{
      athlete_uuid: athlete_uuid,
      occurred_at: occurred_at,
      previous_rank: previous_rank,
      current_rank: current_rank,
      taken_by_athlete: taken_by_athlete(stage_leaderboard_ranked, athlete_uuid, index),
      leaderboard: %{
        name: leaderboard.name,
        gender: leaderboard.gender
      },
      challenge: %{
        name: challenge.name,
        url_slug: challenge.url_slug
      },
      stage: %{
        name: stage.name,
        stage_number: stage.stage_number,
        end_date: stage.end_date,
        url_slug: stage.url_slug
      }
    }
  end

  defp taken_by_athlete(
         %StageLeaderboardRanked{stage_leaderboard_uuid: stage_leaderboard_uuid},
         athlete_uuid,
         index
       )
       when index == 1 do
    case Repo.one(athlete_leaderboard_query(stage_leaderboard_uuid, athlete_uuid)) do
      nil ->
        nil

      athlete_rank ->
        query =
          faster_leaderboard_query(stage_leaderboard_uuid, athlete_rank.elapsed_time_in_seconds)

        case Repo.one(query) do
          nil ->
            nil

          taken_by_rank ->
            %{
              athlete_uuid: taken_by_rank.athlete_uuid,
              firstname: taken_by_rank.athlete_firstname,
              lastname: taken_by_rank.athlete_lastname,
              time_gap_in_seconds:
                athlete_rank.elapsed_time_in_seconds - taken_by_rank.elapsed_time_in_seconds
            }
        end
    end
  end

  defp taken_by_athlete(_stage_leaderboard_ranked, _athlete_uuid, _index), do: nil

  defp was_point_scoring_place?(%LostPlace{previous_rank: previous_rank}), do: previous_rank <= 10

  defp athlete_leaderboard_query(stage_leaderboard_uuid, athlete_uuid) do
    from(r in StageLeaderboardRankingProjection,
      where:
        r.stage_leaderboard_uuid == ^stage_leaderboard_uuid and r.athlete_uuid == ^athlete_uuid
    )
  end

  defp faster_leaderboard_query(stage_leaderboard_uuid, elapsed_time_in_seconds) do
    from(r in StageLeaderboardRankingProjection,
      where:
        r.stage_leaderboard_uuid == ^stage_leaderboard_uuid and
          r.elapsed_time_in_seconds < ^elapsed_time_in_seconds,
      order_by: [desc: r.elapsed_time_in_seconds, desc: r.inserted_at],
      limit: 1
    )
  end
end
