defmodule SegmentChallenge.Athletes.Projections.BadgeProjector do
  use Commanded.Projections.Ecto,
    name: "BadgeProjection",
    start_from: :current

  use SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases

  alias SegmentChallenge.Athletes.Projections.BadgeProjection
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Repo

  project %AthleteAchievedChallengeGoal{} = event, %{created_at: timestamp}, fn multi ->
    %AthleteAchievedChallengeGoal{
      athlete_uuid: athlete_uuid,
      challenge_uuid: challenge_uuid
    } = event

    multi
    |> Ecto.Multi.run(:challenge, fn _repo, _changes ->
      fetch(ChallengeProjection, challenge_uuid)
    end)
    |> Ecto.Multi.run(:badge, fn _repo, changes ->
      %{
        challenge: %ChallengeProjection{
          name: challenge_name,
          start_date: challenge_start_date,
          start_date_local: challenge_start_date_local,
          end_date: challenge_end_date,
          end_date_local: challenge_end_date_local,
          hosted_by_club_uuid: hosted_by_club_uuid,
          hosted_by_club_name: hosted_by_club_name,
          goal: goal,
          goal_units: goal_units,
          goal_recurrence: goal_recurrence,
          accumulate_activities: accumulate_activities
        }
      } = changes

      badge = %BadgeProjection{
        athlete_uuid: athlete_uuid,
        challenge_uuid: challenge_uuid,
        challenge_name: challenge_name,
        challenge_start_date: challenge_start_date,
        challenge_start_date_local: challenge_start_date_local,
        challenge_end_date: challenge_end_date,
        challenge_end_date_local: challenge_end_date_local,
        hosted_by_club_uuid: hosted_by_club_uuid,
        hosted_by_club_name: hosted_by_club_name,
        goal: goal,
        goal_units: goal_units,
        goal_recurrence: goal_recurrence,
        single_activity_goal: !accumulate_activities,
        earned_at: NaiveDateTime.truncate(timestamp, :second)
      }

      Repo.insert(badge)
    end)
  end

  defp fetch(queryable, id) do
    case Repo.get(queryable, id) do
      nil -> {:error, :not_found}
      schema -> {:ok, schema}
    end
  end
end
