defmodule SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjector do
  use Commanded.Projections.Ecto, name: "StageLeaderboardProjection"
  use SegmentChallenge.Leaderboards.StageLeaderboard.Aliases

  alias SegmentChallenge.Challenges.Formatters.SpeedFormatter
  alias SegmentChallenge.Events.CompetitorParticipationInChallengeAllowed
  alias SegmentChallenge.Events.CompetitorParticipationInChallengeLimited
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardEntryProjection
  alias SegmentChallenge.Projections.ChallengeLimitedCompetitorProjection
  alias SegmentChallenge.Projections.AthleteCompetitorProjection
  alias SegmentChallenge.Repo

  project %StageLeaderboardCreated{} = event, fn multi ->
    %StageLeaderboardCreated{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      name: name,
      gender: gender,
      has_goal?: has_goal,
      goal: goal,
      goal_measure: goal_measure,
      goal_units: goal_units,
      rank_by: rank_by,
      rank_order: rank_order,
      accumulate_activities?: accumulate_activities
    } = event

    multi
    |> Ecto.Multi.insert(:stage_leaderboard, %StageLeaderboardProjection{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      name: name,
      gender: gender,
      accumulate_activities: accumulate_activities,
      has_goal: has_goal,
      goal: goal,
      goal_measure: goal_measure,
      goal_units: goal_units,
      rank_by: rank_by,
      rank_order: rank_order
    })
  end

  # Historical projection
  project %StageLeaderboardRanked{stage_efforts: nil} = event, fn multi ->
    %StageLeaderboardRanked{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      positions_gained: positions_gained,
      positions_lost: positions_lost
    } = event

    Enum.reduce(positions_gained ++ positions_lost, multi, fn change, multi ->
      Ecto.Multi.update_all(
        multi,
        "stage_leaderboard_entry_#{change.athlete_uuid}",
        update_query(stage_leaderboard_uuid, change.athlete_uuid),
        set: [
          rank: change.rank
        ]
      )
    end)
  end

  project %StageLeaderboardRanked{} = event, fn multi ->
    %StageLeaderboardRanked{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_efforts: stage_efforts
    } = event

    multi =
      Ecto.Multi.delete_all(
        multi,
        :previous_entries,
        leaderboard_entries_query(stage_leaderboard_uuid)
      )

    Enum.reduce(stage_efforts, multi, fn stage_effort, multi ->
      %StageLeaderboardRanked.StageEffort{
        rank: rank,
        athlete_uuid: athlete_uuid,
        athlete_gender: athlete_gender,
        strava_activity_id: strava_activity_id,
        strava_segment_effort_id: strava_segment_effort_id,
        elapsed_time_in_seconds: elapsed_time_in_seconds,
        moving_time_in_seconds: moving_time_in_seconds,
        start_date: start_date,
        start_date_local: start_date_local,
        distance_in_metres: distance_in_metres,
        elevation_gain_in_metres: elevation_gain_in_metres,
        average_cadence: average_cadence,
        average_watts: average_watts,
        device_watts?: device_watts,
        average_heartrate: average_heartrate,
        max_heartrate: max_heartrate,
        goal_progress: goal_progress,
        stage_effort_count: stage_effort_count
      } = stage_effort

      Ecto.Multi.run(multi, "stage_effort_#{athlete_uuid}", fn repo, _changes ->
        {:ok, athlete} = lookup_athlete(athlete_uuid)

        speed_in_mph = SpeedFormatter.speed_in_mph(distance_in_metres, elapsed_time_in_seconds)
        speed_in_kph = SpeedFormatter.speed_in_kph(distance_in_metres, elapsed_time_in_seconds)

        entry = %StageLeaderboardEntryProjection{
          stage_leaderboard_uuid: stage_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          stage_uuid: stage_uuid,
          rank: rank,
          athlete_uuid: athlete_uuid,
          athlete_gender: athlete_gender,
          athlete_firstname: athlete.firstname,
          athlete_lastname: athlete.lastname,
          athlete_profile: athlete.profile,
          strava_activity_id: strava_activity_id,
          strava_segment_effort_id: strava_segment_effort_id,
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          start_date: start_date,
          start_date_local: start_date_local,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres,
          speed_in_mph: speed_in_mph,
          speed_in_kph: speed_in_kph,
          average_cadence: average_cadence,
          average_watts: average_watts,
          device_watts: device_watts,
          average_heartrate: average_heartrate,
          max_heartrate: max_heartrate,
          goal_progress: goal_progress,
          stage_effort_count: stage_effort_count
        }

        entry =
          case repo.one(limited_competitor_query(challenge_uuid, athlete_uuid)) do
            %ChallengeLimitedCompetitorProjection{} = limited ->
              %ChallengeLimitedCompetitorProjection{reason: reason} = limited

              %StageLeaderboardEntryProjection{
                entry
                | athlete_point_scoring_limited: true,
                  athlete_limit_reason: reason
              }

            nil ->
              entry
          end

        repo.insert(entry,
          on_conflict: [
            set: [
              athlete_firstname: athlete.firstname,
              athlete_lastname: athlete.lastname,
              athlete_profile: athlete.profile,
              strava_activity_id: strava_activity_id,
              strava_segment_effort_id: strava_segment_effort_id,
              elapsed_time_in_seconds: elapsed_time_in_seconds,
              moving_time_in_seconds: moving_time_in_seconds,
              start_date: start_date,
              start_date_local: start_date_local,
              distance_in_metres: distance_in_metres,
              elevation_gain_in_metres: elevation_gain_in_metres,
              speed_in_mph: speed_in_mph,
              speed_in_kph: speed_in_kph,
              average_cadence: average_cadence,
              average_watts: average_watts,
              device_watts: device_watts,
              average_heartrate: average_heartrate,
              max_heartrate: max_heartrate,
              goal_progress: goal_progress,
              stage_effort_count: stage_effort_count
            ]
          ],
          conflict_target: [:stage_leaderboard_uuid, :athlete_uuid]
        )
      end)
    end)
  end

  # Historical projection
  project %AthleteRankedInStageLeaderboard{} = event, fn multi ->
    %AthleteRankedInStageLeaderboard{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      rank: rank,
      athlete_uuid: athlete_uuid,
      athlete_gender: athlete_gender,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      start_date: start_date,
      start_date_local: start_date_local,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts?: device_watts?,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate,
      goal_progress: goal_progress,
      stage_effort_count: stage_effort_count
    } = event

    multi
    |> Ecto.Multi.run(:athlete, fn _repo, _changes -> lookup_athlete(athlete_uuid) end)
    |> Ecto.Multi.run(:stage_leaderboard_entry, fn _repo, %{athlete: athlete} ->
      speed_in_mph = SpeedFormatter.speed_in_mph(distance_in_metres, elapsed_time_in_seconds)
      speed_in_kph = SpeedFormatter.speed_in_kph(distance_in_metres, elapsed_time_in_seconds)

      entry = %StageLeaderboardEntryProjection{
        stage_leaderboard_uuid: stage_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        rank: rank,
        athlete_uuid: athlete_uuid,
        athlete_gender: athlete_gender,
        athlete_firstname: athlete.firstname,
        athlete_lastname: athlete.lastname,
        athlete_profile: athlete.profile,
        strava_activity_id: strava_activity_id,
        strava_segment_effort_id: strava_segment_effort_id,
        elapsed_time_in_seconds: elapsed_time_in_seconds,
        moving_time_in_seconds: moving_time_in_seconds,
        start_date: start_date,
        start_date_local: start_date_local,
        distance_in_metres: distance_in_metres,
        elevation_gain_in_metres: elevation_gain_in_metres,
        speed_in_mph: speed_in_mph,
        speed_in_kph: speed_in_kph,
        average_cadence: average_cadence,
        average_watts: average_watts,
        device_watts: device_watts?,
        average_heartrate: average_heartrate,
        max_heartrate: max_heartrate,
        goal_progress: goal_progress,
        stage_effort_count: stage_effort_count
      }

      entry =
        case Repo.one(limited_competitor_query(challenge_uuid, athlete_uuid)) do
          %ChallengeLimitedCompetitorProjection{} = limited ->
            %ChallengeLimitedCompetitorProjection{reason: reason} = limited

            %StageLeaderboardEntryProjection{
              entry
              | athlete_point_scoring_limited: true,
                athlete_limit_reason: reason
            }

          nil ->
            entry
        end

      Repo.insert(entry,
        on_conflict: [
          set: [
            athlete_firstname: athlete.firstname,
            athlete_lastname: athlete.lastname,
            athlete_profile: athlete.profile,
            strava_activity_id: strava_activity_id,
            strava_segment_effort_id: strava_segment_effort_id,
            elapsed_time_in_seconds: elapsed_time_in_seconds,
            moving_time_in_seconds: moving_time_in_seconds,
            start_date: start_date,
            start_date_local: start_date_local,
            distance_in_metres: distance_in_metres,
            elevation_gain_in_metres: elevation_gain_in_metres,
            speed_in_mph: speed_in_mph,
            speed_in_kph: speed_in_kph,
            average_cadence: average_cadence,
            average_watts: average_watts,
            device_watts: device_watts?,
            average_heartrate: average_heartrate,
            max_heartrate: max_heartrate,
            goal_progress: goal_progress,
            stage_effort_count: stage_effort_count
          ]
        ],
        conflict_target: [:stage_leaderboard_uuid, :athlete_uuid]
      )
    end)
  end

  # Historical projection
  project %AthleteRecordedImprovedStageEffort{} = event, fn multi ->
    %AthleteRecordedImprovedStageEffort{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      athlete_uuid: athlete_uuid,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      start_date: start_date,
      start_date_local: start_date_local,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts?: device_watts?,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate,
      goal_progress: goal_progress,
      stage_effort_count: stage_effort_count
    } = event

    update_leaderboard_entry(multi, stage_leaderboard_uuid, athlete_uuid,
      strava_activity_id: strava_activity_id,
      strava_segment_effort_id: strava_segment_effort_id,
      elapsed_time_in_seconds: elapsed_time_in_seconds,
      moving_time_in_seconds: moving_time_in_seconds,
      start_date: start_date,
      start_date_local: start_date_local,
      distance_in_metres: distance_in_metres,
      elevation_gain_in_metres: elevation_gain_in_metres,
      speed_in_mph: SpeedFormatter.speed_in_mph(distance_in_metres, elapsed_time_in_seconds),
      speed_in_kph: SpeedFormatter.speed_in_kph(distance_in_metres, elapsed_time_in_seconds),
      average_cadence: average_cadence,
      average_watts: average_watts,
      device_watts: device_watts?,
      average_heartrate: average_heartrate,
      max_heartrate: max_heartrate,
      goal_progress: goal_progress,
      stage_effort_count: stage_effort_count
    )
  end

  # Historical projection
  project %AthleteRecordedWorseStageEffort{} = event, fn multi ->
    %AthleteRecordedWorseStageEffort{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      athlete_uuid: athlete_uuid,
      stage_effort_count: stage_effort_count
    } = event

    update_leaderboard_entry(multi, stage_leaderboard_uuid, athlete_uuid,
      stage_effort_count: stage_effort_count
    )
  end

  # Historical projection
  project %AthleteRemovedFromStageLeaderboard{} = event, fn multi ->
    %AthleteRemovedFromStageLeaderboard{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      athlete_uuid: athlete_uuid
    } = event

    Ecto.Multi.delete_all(
      multi,
      :remove_stage_leaderboard_entry,
      update_query(stage_leaderboard_uuid, athlete_uuid)
    )
  end

  # Historical projection
  project %StageEffortRemovedFromStageLeaderboard{} = event, fn multi ->
    alias StageEffortRemovedFromStageLeaderboard.StageEffort

    %StageEffortRemovedFromStageLeaderboard{
      stage_leaderboard_uuid: stage_leaderboard_uuid,
      athlete_uuid: athlete_uuid,
      replaced_by: replacement
    } = event

    case replacement do
      %StageEffort{} = stage_effort ->
        %StageEffort{
          strava_activity_id: strava_activity_id,
          strava_segment_effort_id: strava_segment_effort_id,
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          start_date: start_date,
          start_date_local: start_date_local,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres,
          average_cadence: average_cadence,
          average_watts: average_watts,
          device_watts?: device_watts?,
          average_heartrate: average_heartrate,
          max_heartrate: max_heartrate,
          goal_progress: goal_progress,
          stage_effort_count: stage_effort_count
        } = stage_effort

        # Update entry with replacement
        update_leaderboard_entry(multi, stage_leaderboard_uuid, athlete_uuid,
          strava_activity_id: strava_activity_id,
          strava_segment_effort_id: strava_segment_effort_id,
          elapsed_time_in_seconds: elapsed_time_in_seconds,
          moving_time_in_seconds: moving_time_in_seconds,
          start_date: start_date,
          start_date_local: start_date_local,
          distance_in_metres: distance_in_metres,
          elevation_gain_in_metres: elevation_gain_in_metres,
          speed_in_mph: SpeedFormatter.speed_in_mph(distance_in_metres, elapsed_time_in_seconds),
          speed_in_kph: SpeedFormatter.speed_in_kph(distance_in_metres, elapsed_time_in_seconds),
          average_cadence: average_cadence,
          average_watts: average_watts,
          device_watts: device_watts?,
          average_heartrate: average_heartrate,
          max_heartrate: max_heartrate,
          goal_progress: goal_progress,
          stage_effort_count: stage_effort_count
        )

      nil ->
        # Remove stage effort from leaderboard
        Ecto.Multi.delete_all(
          multi,
          :remove_stage_leaderboard_entry,
          update_query(stage_leaderboard_uuid, athlete_uuid)
        )
    end
  end

  project %CompetitorParticipationInChallengeAllowed{} = event, fn multi ->
    %CompetitorParticipationInChallengeAllowed{
      challenge_uuid: challenge_uuid,
      athlete_uuid: athlete_uuid
    } = event

    multi
    |> Ecto.Multi.update_all(
      :stage_leaderboard_entry,
      leaderboard_entry_query(challenge_uuid, athlete_uuid),
      set: [
        athlete_point_scoring_limited: false,
        athlete_limit_reason: nil
      ]
    )
    |> Ecto.Multi.delete_all(
      :challenge_limited_competitor,
      limited_competitor_query(challenge_uuid, athlete_uuid)
    )
  end

  project %CompetitorParticipationInChallengeLimited{} = event, fn multi ->
    %CompetitorParticipationInChallengeLimited{
      challenge_uuid: challenge_uuid,
      athlete_uuid: athlete_uuid,
      reason: reason
    } = event

    multi
    |> Ecto.Multi.update_all(
      :stage_leaderboard_entry,
      leaderboard_entry_query(challenge_uuid, athlete_uuid),
      set: [
        athlete_point_scoring_limited: true,
        athlete_limit_reason: reason
      ]
    )
    |> Ecto.Multi.insert(:challenge_limited_competitor, %ChallengeLimitedCompetitorProjection{
      challenge_uuid: challenge_uuid,
      athlete_uuid: athlete_uuid,
      reason: reason
    })
  end

  project %StageLeaderboardCleared{} = event, fn multi ->
    %StageLeaderboardCleared{stage_leaderboard_uuid: stage_leaderboard_uuid} = event

    Ecto.Multi.delete_all(
      multi,
      :stage_leaderboard,
      leaderboard_entries_query(stage_leaderboard_uuid)
    )
  end

  defp lookup_athlete(athlete_uuid) do
    query =
      from(a in AthleteCompetitorProjection, where: a.athlete_uuid == ^athlete_uuid, limit: 1)

    case Repo.one(query) do
      %AthleteCompetitorProjection{} = a -> {:ok, a}
      nil -> {:ok, %{firstname: "Strava", lastname: "Athlete", profile: nil}}
    end
  end

  defp update_leaderboard_entry(multi, stage_leaderboard_uuid, athlete_uuid, entry_update) do
    Ecto.Multi.update_all(
      multi,
      :stage_leaderboard_entry,
      update_query(stage_leaderboard_uuid, athlete_uuid),
      set: entry_update
    )
  end

  defp leaderboard_entries_query(stage_leaderboard_uuid) do
    from(entry in StageLeaderboardEntryProjection,
      where: entry.stage_leaderboard_uuid == ^stage_leaderboard_uuid
    )
  end

  defp update_query(stage_leaderboard_uuid, athlete_uuid) do
    from(entry in StageLeaderboardEntryProjection,
      where:
        entry.stage_leaderboard_uuid == ^stage_leaderboard_uuid and
          entry.athlete_uuid == ^athlete_uuid
    )
  end

  defp leaderboard_entry_query(challenge_uuid, athlete_uuid) do
    from(entry in StageLeaderboardEntryProjection,
      where: entry.challenge_uuid == ^challenge_uuid and entry.athlete_uuid == ^athlete_uuid
    )
  end

  defp limited_competitor_query(challenge_uuid, athlete_uuid) do
    from(c in ChallengeLimitedCompetitorProjection,
      where: c.challenge_uuid == ^challenge_uuid and c.athlete_uuid == ^athlete_uuid
    )
  end
end
