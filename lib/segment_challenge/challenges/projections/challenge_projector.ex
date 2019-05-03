defmodule SegmentChallenge.Projections.ChallengeProjector do
  use Commanded.Projections.Ecto,
    name: "ChallengeProjection",
    consistency: :strong

  use SegmentChallenge.Challenges.Challenge.Aliases
  use SegmentChallenge.Stages.Stage.Aliases

  import SegmentChallenge.Challenges.Services.Markdown, only: [markdown_to_html: 1]

  alias SegmentChallenge.Projections.ChallengeCompetitorProjection
  alias SegmentChallenge.Projections.ChallengeProjection

  project %ChallengeCreated{} = event, fn multi ->
    %ChallengeCreated{
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      created_by_athlete_uuid: created_by_athlete_uuid,
      created_by_athlete_name: created_by_athlete_name,
      hosted_by_club_uuid: hosted_by_club_uuid,
      hosted_by_club_name: hosted_by_club_name,
      restricted_to_club_members?: restricted_to_club_members,
      allow_private_activities?: allow_private_activities,
      included_activity_types: included_activity_types,
      accumulate_activities?: accumulate_activities,
      private: private,
      url_slug: url_slug
    } = event

    challenge = %ChallengeProjection{
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description_markdown: description,
      description_html: markdown_to_html(description),
      summary_html: description |> summarize() |> markdown_to_html(),
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      created_by_athlete_uuid: created_by_athlete_uuid,
      created_by_athlete_name: created_by_athlete_name,
      hosted_by_club_uuid: hosted_by_club_uuid,
      hosted_by_club_name: hosted_by_club_name,
      restricted_to_club_members: restricted_to_club_members,
      allow_private_activities: allow_private_activities,
      included_activity_types: included_activity_types,
      accumulate_activities: accumulate_activities,
      private: private,
      url_slug: url_slug,
      status: "pending"
    }

    Ecto.Multi.insert(multi, :challenge, challenge)
  end

  project %ChallengeGoalConfigured{} = event, fn multi ->
    %ChallengeGoalConfigured{
      challenge_uuid: challenge_uuid,
      goal: goal,
      goal_units: goal_units,
      goal_recurrence: goal_recurrence
    } = event

    update_challenge(multi, challenge_uuid,
      set: [
        has_goal: true,
        goal: goal,
        goal_units: goal_units,
        goal_recurrence: goal_recurrence
      ]
    )
  end

  project %StageIncludedInChallenge{} = event, fn multi ->
    %StageIncludedInChallenge{challenge_uuid: challenge_uuid} = event

    update_challenge(multi, challenge_uuid, inc: [stage_count: 1])
  end

  project %StageRemovedFromChallenge{} = event, fn multi ->
    %StageRemovedFromChallenge{challenge_uuid: challenge_uuid} = event

    update_challenge(multi, challenge_uuid, inc: [stage_count: -1])
  end

  project %ChallengeRenamed{} = event, fn multi ->
    %ChallengeRenamed{challenge_uuid: challenge_uuid, name: name, url_slug: url_slug} = event

    update_challenge(multi, challenge_uuid, set: [name: name, url_slug: url_slug])
  end

  project %ChallengeStagesConfigured{challenge_uuid: challenge_uuid}, fn multi ->
    update_challenge(multi, challenge_uuid, set: [stages_configured: true])
  end

  project %StageRemovedFromChallenge{challenge_uuid: challenge_uuid}, fn multi ->
    update_challenge(multi, challenge_uuid, set: [stages_configured: false])
  end

  project %ChallengeCancelled{challenge_uuid: challenge_uuid}, fn multi ->
    Ecto.Multi.delete_all(multi, :challenge, challenge_query(challenge_uuid))
  end

  project %ChallengeHosted{challenge_uuid: challenge_uuid}, fn multi ->
    update_challenge(multi, challenge_uuid, set: [status: "hosted"])
  end

  project %ChallengeApproved{challenge_uuid: challenge_uuid}, fn multi ->
    update_challenge(multi, challenge_uuid, set: [status: "upcoming"])
  end

  project %CompetitorJoinedChallenge{} = joined, %{created_at: joined_at}, fn multi ->
    %CompetitorJoinedChallenge{challenge_uuid: challenge_uuid, athlete_uuid: athlete_uuid} =
      joined

    multi
    |> Ecto.Multi.insert(
      :challenge_competitor,
      %ChallengeCompetitorProjection{
        athlete_uuid: athlete_uuid,
        challenge_uuid: challenge_uuid,
        joined_at: NaiveDateTime.truncate(joined_at, :second)
      },
      on_conflict: :nothing,
      conflict_target: [:athlete_uuid, :challenge_uuid]
    )
    |> Ecto.Multi.update_all(:challenge, competitor_count_update_query(challenge_uuid, 1), [])
  end

  project %CompetitorsJoinedChallenge{} = event, %{created_at: joined_at}, fn multi ->
    %CompetitorsJoinedChallenge{challenge_uuid: challenge_uuid, competitors: competitors} = event

    competitors
    |> Enum.reduce(multi, fn competitor, multi ->
      Ecto.Multi.insert(
        multi,
        UUID.uuid4(),
        %ChallengeCompetitorProjection{
          athlete_uuid: competitor.athlete_uuid,
          challenge_uuid: challenge_uuid,
          joined_at: NaiveDateTime.truncate(joined_at, :second)
        },
        on_conflict: :nothing,
        conflict_target: [:athlete_uuid, :challenge_uuid]
      )
    end)
    |> Ecto.Multi.update_all(
      :challenge,
      competitor_count_update_query(challenge_uuid, length(competitors)),
      []
    )
  end

  project %CompetitorLeftChallenge{} = event, fn multi ->
    %CompetitorLeftChallenge{athlete_uuid: athlete_uuid, challenge_uuid: challenge_uuid} = event

    multi
    |> Ecto.Multi.update_all(:challenge, competitor_count_update_query(challenge_uuid, -1), [])
    |> Ecto.Multi.delete_all(
      :challenge_competitor,
      challenge_competitor_query(athlete_uuid, challenge_uuid),
      []
    )
  end

  project %CompetitorExcludedFromChallenge{} = event, fn multi ->
    %CompetitorExcludedFromChallenge{
      athlete_uuid: athlete_uuid,
      challenge_uuid: challenge_uuid
    } = event

    multi
    |> Ecto.Multi.update_all(:challenge, competitor_count_update_query(challenge_uuid, -1), [])
    |> Ecto.Multi.delete_all(
      :challenge_competitor,
      challenge_competitor_query(athlete_uuid, challenge_uuid),
      []
    )
  end

  project %ChallengeStarted{challenge_uuid: challenge_uuid}, fn multi ->
    update_challenge(multi, challenge_uuid, set: [status: "active"])
  end

  project %ChallengeEnded{challenge_uuid: challenge_uuid}, fn multi ->
    update_challenge(multi, challenge_uuid, set: [status: "past"])
  end

  project %ChallengeDurationAdjusted{} = event, fn multi ->
    %ChallengeDurationAdjusted{
      challenge_uuid: challenge_uuid,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = event

    update_challenge(multi, challenge_uuid,
      set: [
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local
      ]
    )
  end

  project %ChallengeIncludedActivitiesAdjusted{} = event, fn multi ->
    %ChallengeIncludedActivitiesAdjusted{
      challenge_uuid: challenge_uuid,
      included_activity_types: included_activity_types
    } = event

    update_challenge(multi, challenge_uuid,
      set: [included_activity_types: included_activity_types]
    )
  end

  project %ChallengeDescriptionEdited{} = event, fn multi ->
    %ChallengeDescriptionEdited{challenge_uuid: challenge_uuid, description: description} = event

    update_challenge(multi, challenge_uuid,
      set: [
        description_markdown: description,
        description_html: markdown_to_html(description),
        summary_html: description |> summarize() |> markdown_to_html()
      ]
    )
  end

  project %ChallengeLeaderboardsApproved{} = event, fn multi ->
    %ChallengeLeaderboardsApproved{
      challenge_uuid: challenge_uuid,
      approval_message: approval_message
    } = event

    update_challenge(multi, challenge_uuid,
      set: [
        approved: true,
        results_markdown: approval_message,
        results_html: markdown_to_html(approval_message)
      ]
    )
  end

  project %ChallengeResultsPublished{} = event, fn multi ->
    %ChallengeResultsPublished{challenge_uuid: challenge_uuid, message: message} = event

    update_challenge(multi, challenge_uuid,
      set: [
        results_markdown: message,
        results_html: markdown_to_html(message)
      ]
    )
  end

  project %StageCreated{} = event, fn multi ->
    %StageCreated{
      challenge_uuid: challenge_uuid,
      included_activity_types: included_activity_types
    } = event

    Ecto.Multi.run(multi, :challenge, fn repo, _changes ->
      case repo.one(challenge_query(challenge_uuid)) do
        %ChallengeProjection{} = challenge ->
          %ChallengeProjection{included_activity_types: existing_activity_types} = challenge

          changeset =
            Ecto.Changeset.change(challenge,
              included_activity_types:
                Enum.uniq(existing_activity_types ++ included_activity_types)
            )

          repo.update(changeset)

        nil ->
          {:ok, nil}
      end
    end)
  end

  defp update_challenge(multi, challenge_uuid, updates) do
    Ecto.Multi.update_all(multi, :challenge, challenge_query(challenge_uuid), updates)
  end

  defp summarize(text), do: text |> String.split("\n") |> List.first()

  defp challenge_query(challenge_uuid) do
    from(c in ChallengeProjection, where: c.challenge_uuid == ^challenge_uuid)
  end

  defp competitor_count_update_query(challenge_uuid, by) do
    from(c in ChallengeProjection,
      where: c.challenge_uuid == ^challenge_uuid,
      update: [set: [competitor_count: fragment("COALESCE(competitor_count, 0) + ?", ^by)]]
    )
  end

  defp challenge_competitor_query(athlete_uuid, challenge_uuid) do
    from(c in ChallengeCompetitorProjection,
      where: c.athlete_uuid == ^athlete_uuid and c.challenge_uuid == ^challenge_uuid
    )
  end
end
