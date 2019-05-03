defmodule SegmentChallenge.Projections.NotificationProjection do
  use Ecto.Schema
  use Timex

  alias SegmentChallenge.Notifications
  alias SegmentChallenge.Projections.EmailNotificationSettingProjection
  alias SegmentChallenge.Projections.EmailProjection
  alias SegmentChallenge.Projections.StageLeaderboardRankingProjection

  defmodule Builder do
    use Commanded.Projections.Ecto, name: "NotificationProjection"

    alias SegmentChallenge.Events.AthleteSubscribedToAllNotifications
    alias SegmentChallenge.Events.AthleteRankedInStageLeaderboard
    alias SegmentChallenge.Events.AthleteRecordedImprovedStageEffort
    alias SegmentChallenge.Events.AthleteRemovedFromStageLeaderboard
    alias SegmentChallenge.Events.AthleteSubscribedToNotificationEmails
    alias SegmentChallenge.Events.AthleteUnsubscribedFromNotificationEmails
    alias SegmentChallenge.Events.AthleteNotificationEmailChanged
    alias SegmentChallenge.Events.ChallengeCancelled
    alias SegmentChallenge.Events.ChallengeCreated
    alias SegmentChallenge.Events.ChallengeHosted
    alias SegmentChallenge.Events.StageEffortRemovedFromStageLeaderboard
    alias SegmentChallenge.Events.StageLeaderboardCleared
    alias SegmentChallenge.Events.StageLeaderboardRanked
    alias SegmentChallenge.Notifications.HostChallenge
    alias SegmentChallenge.Notifications.LostPlace
    alias SegmentChallenge.Projections.AthleteCompetitorProjection
    alias SegmentChallenge.Repo

    project %AthleteSubscribedToAllNotifications{
              athlete_uuid: athlete_uuid,
              email: email
            },
            fn multi ->
              Ecto.Multi.insert(
                multi,
                :athlete_email_notification,
                %EmailNotificationSettingProjection{
                  athlete_uuid: athlete_uuid,
                  email: email,
                  lost_place_notification: true
                }
              )
            end

    project %AthleteNotificationEmailChanged{athlete_uuid: athlete_uuid, email: email},
            fn multi ->
              Ecto.Multi.update_all(
                multi,
                :athlete_email_notification,
                athlete_email_notification_query(athlete_uuid),
                set: [
                  email: email
                ]
              )
            end

    project %AthleteSubscribedToNotificationEmails{
              athlete_uuid: athlete_uuid,
              notification_type: notification_type
            },
            fn multi ->
              set = Keyword.new([{String.to_atom(notification_type <> "_notification"), true}])

              Ecto.Multi.update_all(
                multi,
                :athlete_email_notification,
                athlete_email_notification_query(athlete_uuid),
                set: set
              )
            end

    project %AthleteUnsubscribedFromNotificationEmails{
              athlete_uuid: athlete_uuid,
              notification_type: notification_type
            },
            fn multi ->
              set = Keyword.new([{String.to_atom(notification_type <> "_notification"), false}])

              Ecto.Multi.update_all(
                multi,
                :athlete_email_notification,
                athlete_email_notification_query(athlete_uuid),
                set: set
              )
            end

    project %AthleteRankedInStageLeaderboard{} = event, fn multi ->
      %AthleteRankedInStageLeaderboard{
        stage_leaderboard_uuid: stage_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        rank: rank,
        athlete_uuid: athlete_uuid,
        elapsed_time_in_seconds: elapsed_time_in_seconds
      } = event

      multi
      |> Ecto.Multi.run(:stage_leaderboard_ranking, fn _repo, _changes ->
        {athlete_firstname, athlete_lastname} =
          case Repo.get(AthleteCompetitorProjection, athlete_uuid) do
            %AthleteCompetitorProjection{} = athlete ->
              %AthleteCompetitorProjection{firstname: firstname, lastname: lastname} = athlete

              {firstname, lastname}

            nil ->
              {"Strava", "Athlete"}
          end

        ranking = %StageLeaderboardRankingProjection{
          stage_leaderboard_uuid: stage_leaderboard_uuid,
          challenge_uuid: challenge_uuid,
          stage_uuid: stage_uuid,
          rank: rank,
          athlete_uuid: athlete_uuid,
          athlete_firstname: athlete_firstname,
          athlete_lastname: athlete_lastname,
          elapsed_time_in_seconds: elapsed_time_in_seconds
        }

        Repo.insert(ranking)
      end)
    end

    project %StageLeaderboardCleared{stage_leaderboard_uuid: stage_leaderboard_uuid}, fn multi ->
      Ecto.Multi.delete_all(
        multi,
        :stage_leaderboard_ranking,
        stage_leaderboard_rankings_query(stage_leaderboard_uuid),
        []
      )
    end

    project %AthleteRecordedImprovedStageEffort{
              stage_leaderboard_uuid: stage_leaderboard_uuid,
              athlete_uuid: athlete_uuid,
              rank: rank,
              elapsed_time_in_seconds: elapsed_time_in_seconds
            },
            fn multi ->
              Ecto.Multi.update_all(
                multi,
                :stage_leaderboard_ranking,
                athlete_leaderboard_ranking_query(stage_leaderboard_uuid, athlete_uuid),
                set: [
                  rank: rank,
                  elapsed_time_in_seconds: elapsed_time_in_seconds
                ]
              )
            end

    project %StageEffortRemovedFromStageLeaderboard{
              stage_leaderboard_uuid: stage_leaderboard_uuid,
              athlete_uuid: athlete_uuid,
              replaced_by: replacement
            },
            fn multi ->
              case replacement do
                nil ->
                  # remove ranking
                  Ecto.Multi.delete_all(
                    multi,
                    :remove_stage_leaderboard_ranking,
                    athlete_leaderboard_ranking_query(stage_leaderboard_uuid, athlete_uuid)
                  )

                replacement ->
                  # update ranking with replacement
                  Ecto.Multi.update_all(
                    multi,
                    :stage_leaderboard_ranking,
                    athlete_leaderboard_ranking_query(stage_leaderboard_uuid, athlete_uuid),
                    set: [
                      elapsed_time_in_seconds: replacement.elapsed_time_in_seconds
                    ]
                  )
              end
            end

    project %AthleteRemovedFromStageLeaderboard{
              stage_leaderboard_uuid: stage_leaderboard_uuid,
              athlete_uuid: athlete_uuid
            },
            fn multi ->
              Ecto.Multi.delete_all(
                multi,
                :remove_stage_leaderboard_ranking,
                athlete_leaderboard_ranking_query(stage_leaderboard_uuid, athlete_uuid)
              )
            end

    project %StageLeaderboardRanked{stage_efforts: nil}, fn multi -> multi end

    project %StageLeaderboardRanked{has_goal?: false} = event,
            %{created_at: timestamp},
            fn multi ->
              %StageLeaderboardRanked{
                stage_leaderboard_uuid: stage_leaderboard_uuid,
                stage_uuid: stage_uuid,
                challenge_uuid: challenge_uuid,
                stage_efforts: stage_efforts
              } = event

              occurred_at = NaiveDateTime.truncate(timestamp, :second)

              multi =
                Ecto.Multi.delete_all(
                  multi,
                  :previous_entries,
                  stage_leaderboard_rankings_query(stage_leaderboard_uuid)
                )

              stage_efforts
              |> Enum.reduce(multi, fn stage_effort, multi ->
                %StageLeaderboardRanked.StageEffort{
                  rank: rank,
                  athlete_uuid: athlete_uuid,
                  elapsed_time_in_seconds: elapsed_time_in_seconds
                } = stage_effort

                Ecto.Multi.run(multi, "ranking_#{athlete_uuid}", fn repo, _changes ->
                  {athlete_firstname, athlete_lastname} =
                    case repo.get(AthleteCompetitorProjection, athlete_uuid) do
                      %AthleteCompetitorProjection{} = athlete ->
                        %AthleteCompetitorProjection{firstname: firstname, lastname: lastname} =
                          athlete

                        {firstname, lastname}

                      nil ->
                        {"Strava", "Athlete"}
                    end

                  ranking = %StageLeaderboardRankingProjection{
                    stage_leaderboard_uuid: stage_leaderboard_uuid,
                    stage_uuid: stage_uuid,
                    challenge_uuid: challenge_uuid,
                    rank: rank,
                    athlete_uuid: athlete_uuid,
                    athlete_firstname: athlete_firstname,
                    athlete_lastname: athlete_lastname,
                    elapsed_time_in_seconds: elapsed_time_in_seconds
                  }

                  repo.insert(ranking)
                end)
              end)
              |> Ecto.Multi.run(:lost_places, fn repo, _changes ->
                # Create athlete emails
                lost_places =
                  event
                  |> LostPlace.from_stage_leaderboard_ranked(occurred_at)
                  |> Enum.filter(
                    &Notifications.subscribed?(&1.athlete_uuid, :lost_place_notification)
                  )

                for lost_place <- lost_places do
                  # Discard any pending lost place emails, to be replaced by current
                  repo.update_all(
                    athlete_pending_email_query(lost_place.athlete_uuid, "lost_place_email"),
                    set: [
                      send_status: "discarded"
                    ]
                  )

                  email =
                    build_email(
                      lost_place,
                      :lost_place_email,
                      Timex.add(utc_now(), Duration.from_minutes(15))
                    )

                  repo.insert(email)
                end

                {:ok, nil}
              end)
            end

    @doc """
    Send "host challenge" email notification
    """
    project %ChallengeCreated{created_by_athlete_uuid: athlete_uuid} = challenge_created,
            fn multi ->
              case Notifications.subscribed?(athlete_uuid, :host_challenge_notification) do
                true ->
                  enqueue_email(
                    multi,
                    HostChallenge.new(challenge_created),
                    :host_challenge_email,
                    utc_now()
                  )

                false ->
                  multi
              end
            end

    @doc """
    Discard any pending "host challenge" email notification
    """
    project %ChallengeHosted{hosted_by_athlete_uuid: athlete_uuid}, fn multi ->
      Ecto.Multi.update_all(
        multi,
        :email,
        athlete_pending_email_query(athlete_uuid, "host_challenge_email"),
        set: [
          send_status: "discarded"
        ]
      )
    end

    @doc """
    Discard any pending "host challenge" email notification
    """
    project %ChallengeCancelled{cancelled_by_athlete_uuid: athlete_uuid}, fn multi ->
      Ecto.Multi.update_all(
        multi,
        :email,
        athlete_pending_email_query(athlete_uuid, "host_challenge_email"),
        set: [
          send_status: "discarded"
        ]
      )
    end

    defp utc_now do
      SegmentChallenge.Infrastructure.DateTime.Now.to_naive() |> NaiveDateTime.truncate(:second)
    end

    defp enqueue_email(multi, notification, notification_type, send_after) do
      email = build_email(notification, notification_type, send_after)

      Ecto.Multi.insert(multi, "#{email.to}_email", email)
    end

    @email_provider Application.get_env(
                      :segment_challenge,
                      :email_provider,
                      SegmentChallenge.Email
                    )

    defp build_email(notification, notification_type, send_after) do
      %{athlete_uuid: athlete_uuid} = notification

      to = Notifications.email(athlete_uuid)
      email = Kernel.apply(@email_provider, notification_type, [to, notification])

      %EmailProjection{
        type: Atom.to_string(notification_type),
        athlete_uuid: athlete_uuid,
        to: email.to,
        bcc: email.bcc,
        subject: email.subject,
        html_body: email.html_body,
        text_body: email.text_body,
        send_status: "pending",
        send_after: send_after,
        sent_at: nil
      }
    end

    defp athlete_email_notification_query(athlete_uuid) do
      from(e in EmailNotificationSettingProjection,
        where: e.athlete_uuid == ^athlete_uuid
      )
    end

    defp athlete_pending_email_query(athlete_uuid, notification_type) do
      from(e in EmailProjection,
        where:
          e.athlete_uuid == ^athlete_uuid and e.send_status == "pending" and
            e.type == ^notification_type
      )
    end

    defp athlete_leaderboard_ranking_query(stage_leaderboard_uuid, athlete_uuid) do
      from(r in StageLeaderboardRankingProjection,
        where:
          r.stage_leaderboard_uuid == ^stage_leaderboard_uuid and r.athlete_uuid == ^athlete_uuid
      )
    end

    defp stage_leaderboard_rankings_query(stage_leaderboard_uuid) do
      from(r in StageLeaderboardRankingProjection,
        where: r.stage_leaderboard_uuid == ^stage_leaderboard_uuid
      )
    end
  end
end
