defmodule SegmentChallenge.Repo.Migrations.CreateSegmentChallenge do
  use Ecto.Migration

  def change do
    create_activity_feed()
    create_athlete_badges()
    create_athlete_competitors()
    create_challenges()
    create_challenge_competitors()
    create_challenge_leaderboards()
    create_challenge_limited_competitors()
    create_clubs()
    create_emails()
    create_email_notification_settings()
    create_profiles()
    create_stages()
    create_stage_efforts()
    create_stage_leaderboards()
    create_stage_leaderboard_rankings()
    create_stage_results()
    create_strava_access()
    create_strava_cache()
    create_url_slugs()
    create_projection_versions()
  end

  defp create_activity_feed do
    create table(:activity_feed_actors, primary_key: false) do
      add(:actor_uuid, :text, primary_key: true)
      add(:actor_type, :text)
      add(:actor_name, :text)
      add(:actor_image, :text)

      timestamps()
    end

    create table(:activity_feed_activities) do
      add(:published, :naive_datetime)
      add(:actor_type, :text)
      add(:actor_uuid, :text)
      add(:actor_name, :text)
      add(:actor_image, :text)
      add(:verb, :text)
      add(:object_type, :text)
      add(:object_uuid, :text)
      add(:object_name, :text)
      add(:object_image, :text)
      add(:target_type, :text)
      add(:target_uuid, :text)
      add(:target_name, :text)
      add(:target_image, :text)
      add(:message, :text)
      add(:metadata, :map)

      timestamps()
    end

    create(index(:activity_feed_activities, [:actor_type, :actor_uuid, :published]))
    create(index(:activity_feed_activities, [:object_type, :object_uuid, :published]))
    create(index(:activity_feed_activities, [:target_type, :target_uuid, :published]))
  end

  defp create_athlete_badges do
    create table(:athlete_badges) do
      add(:athlete_uuid, :text)
      add(:challenge_uuid, :text)
      add(:challenge_name, :text)
      add(:challenge_leaderboard_uuid, :text)
      add(:challenge_start_date, :naive_datetime)
      add(:challenge_start_date_local, :naive_datetime)
      add(:challenge_end_date, :naive_datetime)
      add(:challenge_end_date_local, :naive_datetime)
      add(:hosted_by_club_uuid, :text)
      add(:hosted_by_club_name, :text)
      add(:goal, :float)
      add(:goal_units, :text)
      add(:goal_recurrence, :text)
      add(:single_activity_goal, :boolean, default: false)
      add(:earned_at, :naive_datetime)

      timestamps()
    end

    create(index(:athlete_badges, [:athlete_uuid]))
  end

  defp create_athlete_competitors do
    create table(:athlete_competitors, primary_key: false) do
      add(:athlete_uuid, :text, primary_key: true)
      add(:firstname, :text)
      add(:lastname, :text)
      add(:email, :text)
      add(:profile, :text)

      timestamps()
    end
  end

  defp create_challenges do
    create table(:challenges, primary_key: false) do
      add(:challenge_uuid, :text, primary_key: true)
      add(:name, :text)
      add(:description_markdown, :text)
      add(:description_html, :text)
      add(:summary_html, :text)
      add(:start_date, :naive_datetime)
      add(:start_date_local, :naive_datetime)
      add(:end_date, :naive_datetime)
      add(:end_date_local, :naive_datetime)
      add(:challenge_type, :text, default: "segment")
      add(:allow_private_activities, :boolean, default: false)
      add(:included_activity_types, {:array, :text}, default: [])
      add(:accumulate_activities, :boolean, default: false)
      add(:has_goal, :boolean, default: false)
      add(:goal, :float)
      add(:goal_units, :text)
      add(:goal_recurrence, :text)
      add(:restricted_to_club_members, :boolean, default: true)
      add(:stage_count, :integer, default: 0)
      add(:created_by_athlete_uuid, :text)
      add(:created_by_athlete_name, :text)
      add(:hosted_by_club_uuid, :text)
      add(:hosted_by_club_name, :text)
      add(:competitor_count, :integer)
      add(:url_slug, :text)
      add(:status, :text)
      add(:stages_configured, :boolean, default: false)
      add(:approved, :boolean)
      add(:results_markdown, :text)
      add(:results_html, :text)
      add(:private, :boolean, default: false)

      timestamps()
    end

    create(index(:challenges, [:created_by_athlete_uuid]))
    create(index(:challenges, [:hosted_by_club_uuid]))
    create(index(:challenges, [:status]))
    create(index(:challenges, [:challenge_type]))
    create(index(:challenges, [:included_activity_types]))
    create(unique_index(:challenges, [:url_slug]))
  end

  defp create_challenge_competitors do
    create table(:challenge_competitors, primary_key: false) do
      add(:athlete_uuid, :text, primary_key: true)
      add(:challenge_uuid, :text, primary_key: true)
      add(:joined_at, :naive_datetime)

      timestamps()
    end

    create(index(:challenge_competitors, [:athlete_uuid]))
    create(index(:challenge_competitors, [:challenge_uuid]))
  end

  defp create_challenge_leaderboards do
    create table(:challenge_leaderboards, primary_key: false) do
      add(:challenge_leaderboard_uuid, :text, primary_key: true)
      add(:challenge_uuid, :text)
      add(:name, :text)
      add(:description, :text)
      add(:gender, :text)
      add(:challenge_type, :text)
      add(:rank_by, :text)
      add(:rank_order, :text)
      add(:accumulate_activities, :boolean, default: false)
      add(:has_goal, :boolean, default: false)
      add(:goal, :float)
      add(:goal_units, :text)
      add(:goal_recurrence, :text)

      timestamps()
    end

    create(index(:challenge_leaderboards, [:challenge_uuid]))

    create table(:challenge_leaderboard_entries) do
      add(:challenge_leaderboard_uuid, :text)
      add(:challenge_uuid, :text)
      add(:rank, :integer)
      add(:points, :integer, default: 0)
      add(:athlete_uuid, :text)
      add(:athlete_firstname, :text)
      add(:athlete_lastname, :text)
      add(:athlete_gender, :text)
      add(:athlete_profile, :text)
      add(:elapsed_time_in_seconds, :integer)
      add(:moving_time_in_seconds, :integer)
      add(:distance_in_metres, :float)
      add(:elevation_gain_in_metres, :float)
      add(:goals, :integer)
      add(:goal_progress, :map)
      add(:activity_count, :integer)

      timestamps()
    end

    create(index(:challenge_leaderboard_entries, [:challenge_leaderboard_uuid, :rank]))

    create(
      unique_index(:challenge_leaderboard_entries, [:challenge_leaderboard_uuid, :athlete_uuid])
    )
  end

  defp create_challenge_limited_competitors do
    create table(:challenge_limited_competitors) do
      add(:challenge_uuid, :text)
      add(:athlete_uuid, :text)
      add(:reason, :text)

      timestamps()
    end

    create(index(:challenge_limited_competitors, [:challenge_uuid]))
    create(unique_index(:challenge_limited_competitors, [:challenge_uuid, :athlete_uuid]))
  end

  defp create_clubs do
    create table(:clubs, primary_key: false) do
      add(:club_uuid, :text, primary_key: true)
      add(:strava_id, :bigint)
      add(:name, :text)
      add(:club_type, :text)
      add(:sport_type, :text)
      add(:description, :text)
      add(:profile, :text)
      add(:city, :text)
      add(:state, :text)
      add(:country, :text)
      add(:website, :text)
      add(:private, :boolean, default: false)
      add(:membership_count, :integer, default: 0)
      add(:last_imported_at, :naive_datetime)

      timestamps()
    end

    create table(:athlete_club_memberships) do
      add(:athlete_uuid, :text)
      add(:club_uuid, :text)

      timestamps()
    end

    create(index(:athlete_club_memberships, [:athlete_uuid]))
    create(index(:athlete_club_memberships, [:club_uuid]))
    create(unique_index(:athlete_club_memberships, [:athlete_uuid, :club_uuid]))
  end

  defp create_emails do
    create table(:emails) do
      add(:athlete_uuid, :text)
      add(:type, :text)
      add(:to, :text)
      add(:bcc, :text)
      add(:subject, :text)
      add(:html_body, :text)
      add(:text_body, :text)
      add(:send_after, :naive_datetime)
      add(:send_status, :text, default: "pending")

      timestamps()

      add(:sent_at, :naive_datetime)
    end

    # Indexes for pending emails
    create(index(:emails, [:to, :send_status], where: "send_status = 'pending'"))
    create(index(:emails, [:send_status], where: "send_status = 'pending'"))
    create(index(:emails, [:athlete_uuid], where: "send_status = 'pending'"))
  end

  defp create_email_notification_settings do
    create table(:email_notification_settings, primary_key: false) do
      add(:athlete_uuid, :text, primary_key: true)
      add(:email, :text)
      add(:approve_leaderboards_notification, :boolean, default: true)
      add(:host_challenge_notification, :boolean, default: true)
      add(:lost_place_notification, :boolean, default: true)

      timestamps()
    end
  end

  defp create_profiles do
    create table(:profiles, primary_key: false) do
      add(:source_uuid, :text, primary_key: true)
      add(:source, :text)
      add(:profile, :text)

      timestamps()
    end

    create(unique_index(:profiles, [:source_uuid, :source]))
  end

  defp create_stages do
    create table(:stages, primary_key: false) do
      add(:stage_uuid, :text, primary_key: true)
      add(:challenge_uuid, :text)
      add(:stage_number, :integer)
      add(:name, :text)
      add(:description_markdown, :text)
      add(:description_html, :text)
      add(:stage_type, :text)
      add(:start_date, :naive_datetime)
      add(:start_date_local, :naive_datetime)
      add(:end_date, :naive_datetime)
      add(:end_date_local, :naive_datetime)
      add(:start_description_html, :text)
      add(:end_description_html, :text)
      add(:allow_private_activities, :boolean, default: false)
      add(:included_activity_types, {:array, :string})
      add(:accumulate_activities, :boolean, default: false)
      add(:has_goal, :boolean, default: false)
      add(:goal, :float)
      add(:goal_units, :text)
      add(:strava_segment_id, :bigint)
      add(:distance_in_metres, :float)
      add(:average_grade, :float)
      add(:maximum_grade, :float)
      add(:start_latitude, :float)
      add(:start_longitude, :float)
      add(:end_latitude, :float)
      add(:end_longitude, :float)
      add(:map_polyline, :text)
      add(:attempt_count, :integer)
      add(:competitor_count, :integer)
      add(:refreshed_at, :naive_datetime)
      add(:url_slug, :text)
      add(:created_by_athlete_uuid, :text)
      add(:visible, :boolean, default: false)
      add(:approved, :boolean, default: false)
      add(:results_markdown, :text)
      add(:results_html, :text)
      add(:status, :text)

      timestamps()
    end

    create(index(:stages, [:challenge_uuid]))
    create(index(:stages, [:stage_uuid, :visible], where: "visible = true"))
    create(unique_index(:stages, [:challenge_uuid, :url_slug]))
  end

  defp create_stage_efforts do
    create table(:stage_efforts) do
      add(:stage_uuid, :text, null: false)
      add(:athlete_uuid, :text, null: false)
      add(:athlete_gender, :text)
      add(:strava_activity_id, :bigint)
      add(:strava_segment_effort_id, :bigint)
      add(:activity_type, :text)
      add(:elapsed_time_in_seconds, :integer)
      add(:moving_time_in_seconds, :integer)
      add(:distance_in_metres, :float)
      add(:elevation_gain_in_metres, :float)
      add(:start_date, :naive_datetime)
      add(:start_date_local, :naive_datetime)
      add(:speed_in_mph, :float)
      add(:speed_in_kph, :float)
      add(:trainer, :boolean)
      add(:commute, :boolean)
      add(:manual, :boolean)
      add(:private, :boolean)
      add(:flagged, :boolean)
      add(:flagged_reason, :text)
      add(:average_cadence, :float)
      add(:average_watts, :float)
      add(:device_watts, :boolean, default: false)
      add(:average_heartrate, :float)
      add(:max_heartrate, :float)

      timestamps()
    end
  end

  defp create_stage_leaderboards do
    create table(:stage_leaderboards, primary_key: false) do
      add(:stage_leaderboard_uuid, :text, primary_key: true)
      add(:stage_uuid, :text)
      add(:challenge_uuid, :text)
      add(:name, :text)
      add(:gender, :text)
      add(:url_slug, :text)
      add(:stage_type, :text, default: "segment")
      add(:rank_by, :text, default: "elapsed_time_in_seconds")
      add(:rank_order, :text, default: "asc")
      add(:accumulate_activities, :boolean, default: false)
      add(:has_goal, :boolean, default: false)
      add(:goal, :float)
      add(:goal_units, :text)
      add(:goal_measure, :text)

      timestamps()
    end

    create(index(:stage_leaderboards, [:stage_uuid]))
    create(index(:stage_leaderboards, [:challenge_uuid]))

    create table(:stage_leaderboard_entries) do
      add(:stage_leaderboard_uuid, :text)
      add(:stage_uuid, :text)
      add(:challenge_uuid, :text)
      add(:rank, :integer)
      add(:athlete_uuid, :text)
      add(:athlete_firstname, :text)
      add(:athlete_lastname, :text)
      add(:athlete_gender, :text)
      add(:athlete_profile, :text)
      add(:strava_activity_id, :bigint)
      add(:strava_segment_effort_id, :bigint)
      add(:elapsed_time_in_seconds, :integer)
      add(:moving_time_in_seconds, :integer)
      add(:elevation_gain_in_metres, :float)
      add(:goal_progress, :decimal)
      add(:start_date, :naive_datetime)
      add(:start_date_local, :naive_datetime)
      add(:distance_in_metres, :float)
      add(:speed_in_mph, :float)
      add(:speed_in_kph, :float)
      add(:average_cadence, :float)
      add(:average_watts, :float)
      add(:device_watts, :boolean, default: false)
      add(:average_heartrate, :float)
      add(:max_heartrate, :float)
      add(:attempt_count, :integer)
      add(:stage_effort_count, :integer)
      add(:athlete_point_scoring_limited, :boolean, default: false)
      add(:athlete_limit_reason, :text)

      timestamps()
    end

    create(index(:stage_leaderboard_entries, [:stage_leaderboard_uuid, :rank]))
    create(unique_index(:stage_leaderboard_entries, [:stage_leaderboard_uuid, :athlete_uuid]))
  end

  defp create_stage_leaderboard_rankings do
    create table(:stage_leaderboard_rankings) do
      add(:stage_leaderboard_uuid, :text)
      add(:stage_uuid, :text)
      add(:challenge_uuid, :text)
      add(:rank, :integer)
      add(:athlete_uuid, :text)
      add(:athlete_firstname, :text)
      add(:athlete_lastname, :text)
      add(:athlete_profile, :text)
      add(:elapsed_time_in_seconds, :integer)

      timestamps()
    end

    create(unique_index(:stage_leaderboard_rankings, [:stage_leaderboard_uuid, :athlete_uuid]))
    create(index(:stage_leaderboard_rankings, [:stage_leaderboard_uuid, :rank]))
  end

  defp create_stage_results do
    create table(:stage_result_challenge_stages) do
      add(:challenge_uuid, :text)
      add(:stage_uuid, :text)
      add(:stage_number, :integer)

      timestamps()
    end

    create(index(:stage_result_challenge_stages, [:challenge_uuid]))

    create table(:stage_result_challenge_leaderboards) do
      add(:challenge_uuid, :text)
      add(:challenge_leaderboard_uuid, :text)
      add(:name, :text)
      add(:description, :text)
      add(:gender, :text)
      add(:rank_by, :text, default: "points")
      add(:rank_order, :text, default: "desc")
      add(:has_goal, :boolean, default: false)
      add(:goal, :float)
      add(:goal_units, :text)
      add(:goal_recurrence, :text)

      timestamps()
    end

    create(index(:stage_result_challenge_leaderboards, [:challenge_uuid]))

    create table(:stage_results) do
      add(:challenge_uuid, :text)
      add(:challenge_leaderboard_uuid, :text)
      add(:stage_uuid, :text)
      add(:stage_number, :integer)
      add(:current_stage_number, :integer)
      add(:name, :text)
      add(:description, :text)
      add(:gender, :text)
      add(:rank_by, :text, default: "points")
      add(:rank_order, :text, default: "desc")
      add(:has_goal, :boolean, default: false)
      add(:goal, :float)
      add(:goal_units, :text)
      add(:goal_recurrence, :text)

      timestamps()
    end

    create(index(:stage_results, [:challenge_uuid]))
    create(index(:stage_results, [:challenge_leaderboard_uuid]))
    create(index(:stage_results, [:challenge_leaderboard_uuid, :stage_number]))
    create(index(:stage_results, [:stage_uuid]))

    create table(:stage_result_entries) do
      add(:challenge_uuid, :text)
      add(:challenge_leaderboard_uuid, :text)
      add(:stage_uuid, :text)
      add(:stage_number, :integer)
      add(:rank, :integer)
      add(:rank_change, :integer, default: 0)
      add(:points, :integer, default: 0)
      add(:points_gained, :integer, default: 0)
      add(:athlete_uuid, :text)
      add(:athlete_firstname, :text)
      add(:athlete_lastname, :text)
      add(:athlete_gender, :text)
      add(:athlete_profile, :text)
      add(:elapsed_time_in_seconds, :integer)
      add(:elapsed_time_in_seconds_gained, :integer)
      add(:moving_time_in_seconds, :integer)
      add(:moving_time_in_seconds_gained, :integer)
      add(:distance_in_metres, :float)
      add(:distance_in_metres_gained, :float)
      add(:elevation_gain_in_metres, :float)
      add(:elevation_gain_in_metres_gained, :float)
      add(:goals, :integer)
      add(:goals_gained, :integer)
      add(:activity_count, :integer)

      timestamps()
    end

    create(index(:stage_result_entries, [:challenge_uuid]))
    create(index(:stage_result_entries, [:challenge_leaderboard_uuid]))

    create(
      index(:stage_result_entries, [
        :challenge_uuid,
        :challenge_leaderboard_uuid,
        :stage_uuid,
        :athlete_uuid
      ])
    )

    create(index(:stage_result_entries, [:stage_uuid]))
    create(index(:stage_result_entries, [:challenge_leaderboard_uuid, :stage_uuid, :rank]))
  end

  defp create_strava_access do
    create table(:strava_access, primary_key: false) do
      add(:athlete_uuid, :text, primary_key: true)
      add(:access_token, :text, null: false)
      add(:refresh_token, :text)

      timestamps()
    end
  end

  defp create_strava_cache do
    create table(:strava_cache, primary_key: false) do
      add(:strava_id, :bigint, primary_key: true)
      add(:strava_type, :text, primary_key: true)
      add(:payload, :text, null: false)

      timestamps()
    end
  end

  defp create_url_slugs do
    create table(:url_slugs) do
      add(:source, :text)
      add(:source_uuid, :text)
      add(:slug, :text)

      timestamps()
    end

    create(unique_index(:url_slugs, [:source, :source_uuid]))
    create(unique_index(:url_slugs, [:source, :slug]))
  end

  defp create_projection_versions do
    create table(:projection_versions, primary_key: false) do
      add(:projection_name, :text, primary_key: true)
      add(:last_seen_event_number, :bigint)

      timestamps()
    end
  end
end
