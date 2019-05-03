defmodule SegmentChallenge.Challenges.VirtualRace do
  use SegmentChallenge.Challenges.Challenge.Aliases

  import SegmentChallenge.Challenges.ChallengeGuards

  alias SegmentChallenge.Challenges.Challenge

  defmacro __using__(_opts) do
    quote do
      defp request_stages(%Challenge{challenge_type: challenge_type} = challenge, _stages)
           when is_virtual_race(challenge_type) do
        %Challenge{
          challenge_uuid: challenge_uuid,
          name: challenge_name,
          description: challenge_description,
          start_date: challenge_start_date,
          start_date_local: challenge_start_date_local,
          end_date: challenge_end_date,
          end_date_local: challenge_end_date_local,
          allow_private_activities?: allow_private_activities?,
          included_activity_types: included_activity_types,
          accumulate_activities?: accumulate_activities?,
          goal: goal,
          goal_units: goal_units,
          created_by_athlete_uuid: created_by_athlete_uuid
        } = challenge

        # Request a single stage for entire challenge duration
        %ChallengeStageRequested{
          challenge_uuid: challenge_uuid,
          stage_uuid: UUID.uuid4(),
          stage_number: 1,
          stage_type: challenge_type,
          name: challenge_name,
          description: challenge_description,
          start_date: challenge_start_date,
          start_date_local: challenge_start_date_local,
          end_date: challenge_end_date,
          end_date_local: challenge_end_date_local,
          allow_private_activities?: allow_private_activities?,
          included_activity_types: included_activity_types,
          accumulate_activities?: accumulate_activities?,
          has_goal?: true,
          goal: goal,
          goal_units: goal_units,
          visible?: true,
          created_by_athlete_uuid: created_by_athlete_uuid
        }
      end

      defp request_challenge_leaderboards(%Challenge{challenge_type: challenge_type} = challenge)
           when is_virtual_race(challenge_type) do
        %Challenge{
          challenge_uuid: challenge_uuid,
          challenge_type: challenge_type,
          goal: goal,
          goal_units: goal_units
        } = challenge

        Enum.map(["M", "F"], fn gender ->
          %ChallengeLeaderboardRequested{
            challenge_uuid: challenge_uuid,
            challenge_type: challenge_type,
            name: "Overall",
            description: "Overall",
            gender: gender,
            rank_by: "elapsed_time_in_seconds",
            rank_order: "asc",
            has_goal?: true,
            goal: goal,
            goal_units: goal_units
          }
        end)
      end
    end
  end
end
