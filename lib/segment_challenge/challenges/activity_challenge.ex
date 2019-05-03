defmodule SegmentChallenge.Challenges.ActivityChallenge do
  use SegmentChallenge.Challenges.Challenge.Aliases

  import SegmentChallenge.Challenges.ChallengeGuards

  alias SegmentChallenge.Challenges.Challenge

  defmacro __using__(_opts) do
    quote do
      defp request_stages(%Challenge{challenge_type: challenge_type} = challenge, stages)
           when is_activity_challenge(challenge_type) do
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
          has_goal?: has_goal?,
          goal: goal,
          goal_units: goal_units,
          accumulate_activities?: accumulate_activities?,
          created_by_athlete_uuid: created_by_athlete_uuid
        } = challenge

        case stages do
          none when none in [nil, []] ->
            #  Create single stage for entire challenge duration
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
              has_goal?: has_goal?,
              goal: goal,
              goal_units: goal_units,
              visible?: true,
              created_by_athlete_uuid: created_by_athlete_uuid
            }

          stages when is_list(stages) ->
            Enum.map(stages, fn stage ->
              %CreateChallenge.ChallengeStage{
                name: name,
                description: description,
                stage_number: stage_number,
                start_date: start_date,
                start_date_local: start_date_local,
                end_date: end_date,
                end_date_local: end_date_local
              } = stage

              %ChallengeStageRequested{
                challenge_uuid: challenge_uuid,
                stage_uuid: UUID.uuid4(),
                stage_number: stage_number,
                stage_type: challenge_type,
                name: name,
                description: description,
                start_date: start_date,
                start_date_local: start_date_local,
                end_date: end_date,
                end_date_local: end_date_local,
                allow_private_activities?: allow_private_activities?,
                included_activity_types: included_activity_types,
                accumulate_activities?: accumulate_activities?,
                has_goal?: has_goal?,
                goal: goal,
                goal_units: goal_units,
                visible?: true,
                created_by_athlete_uuid: created_by_athlete_uuid
              }
            end)
        end
      end

      defp request_challenge_leaderboards(%Challenge{challenge_type: challenge_type} = challenge)
           when is_activity_challenge(challenge_type) do
        %Challenge{
          challenge_uuid: challenge_uuid,
          challenge_type: challenge_type,
          has_goal?: has_goal?,
          goal: goal,
          goal_units: goal_units,
          goal_recurrence: goal_recurrence
        } = challenge

        rank_by =
          if has_goal? and goal_recurrence != "none" do
            "goals"
          else
            case challenge_type do
              "distance" -> "distance_in_metres"
              "duration" -> "moving_time_in_seconds"
              "elevation" -> "elevation_gain_in_metres"
            end
          end

        Enum.map(["M", "F"], fn gender ->
          name = description = challenge_leaderboard_name(challenge_type, gender)

          %ChallengeLeaderboardRequested{
            challenge_uuid: challenge_uuid,
            challenge_type: challenge_type,
            name: name,
            description: description,
            gender: gender,
            rank_by: rank_by,
            rank_order: "desc",
            has_goal?: has_goal?,
            goal: goal,
            goal_units: goal_units
          }
        end)
      end

      defp challenge_leaderboard_name(challenge_type, gender)
      defp challenge_leaderboard_name("elevation", "M"), do: "KOM"
      defp challenge_leaderboard_name("elevation", "F"), do: "QOM"
      defp challenge_leaderboard_name(_challenge_type, _gender), do: "Overall"
    end
  end
end
