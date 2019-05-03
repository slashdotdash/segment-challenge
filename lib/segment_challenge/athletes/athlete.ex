defmodule SegmentChallenge.Athletes.Athlete do
  @moduledoc """
  Athletes are users, users are athletes.
  """
  defstruct [
    :athlete_uuid,
    :strava_id,
    :firstname,
    :lastname,
    :profile,
    :city,
    :country,
    :gender,
    :email,
    :state,
    club_memberships: MapSet.new(),
    starred_segments: MapSet.new()
  ]

  import SegmentChallenge.Enumerable, only: [pluck: 2]

  alias SegmentChallenge.Commands.{
    ImportAthlete,
    JoinClub,
    LeaveClub,
    SetAthleteClubMemberships
  }

  alias SegmentChallenge.Events.{
    AthleteGenderChanged,
    AthleteImported,
    AthleteJoinedClub,
    AthleteLeftClub,
    AthleteEmailChanged,
    AthleteProfileChanged,
    AthleteRenamed,
    AthleteStarredStravaSegment,
    AthleteUnstarredStravaSegment
  }

  alias SegmentChallenge.Athletes.Athlete

  def identity(strava_id), do: "athlete-#{strava_id}"

  @doc """
  Import an athlete from Strava.
  """
  def import_athlete(athlete, import_athlete)

  # Compare athlete's name, email & profile image
  def import_athlete(%Athlete{state: :imported} = athlete, %ImportAthlete{} = import_athlete) do
    [
      &renamed/2,
      &email_changed/2,
      &profile_changed/2,
      &gender_changed/2
    ]
    |> Enum.map(fn change ->
      change.(athlete, import_athlete)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def import_athlete(%Athlete{state: nil}, %ImportAthlete{} = import_athlete) do
    firstname = String.trim(import_athlete.firstname)
    lastname = String.trim(import_athlete.lastname)
    fullname = fullname(firstname, lastname)

    %AthleteImported{
      athlete_uuid: import_athlete.athlete_uuid,
      strava_id: import_athlete.strava_id,
      firstname: firstname,
      lastname: lastname,
      fullname: fullname,
      profile: import_athlete.profile,
      city: import_athlete.city,
      state: import_athlete.state,
      country: import_athlete.country,
      gender: import_athlete.gender,
      date_preference: import_athlete.date_preference,
      measurement_preference: import_athlete.measurement_preference,
      email: import_athlete.email,
      ftp: import_athlete.ftp,
      weight: import_athlete.weight
    }
  end

  def set_club_memberships(%Athlete{} = athlete, %SetAthleteClubMemberships{
        club_uuids: club_uuids
      }) do
    join_new_clubs(athlete, club_uuids) ++ leave_old_clubs(athlete, club_uuids)
  end

  def join_club(%Athlete{} = athlete, %JoinClub{club_uuid: club_uuid}) do
    %Athlete{athlete_uuid: athlete_uuid, firstname: firstname, lastname: lastname, gender: gender} =
      athlete

    case is_club_member?(athlete, club_uuid) do
      true ->
        []

      false ->
        %AthleteJoinedClub{
          athlete_uuid: athlete_uuid,
          club_uuid: club_uuid,
          firstname: firstname,
          lastname: lastname,
          gender: gender
        }
    end
  end

  def leave_club(%Athlete{} = athlete, %LeaveClub{club_uuid: club_uuid}) do
    %Athlete{athlete_uuid: athlete_uuid} = athlete

    case is_club_member?(athlete, club_uuid) do
      true -> %AthleteLeftClub{athlete_uuid: athlete_uuid, club_uuid: club_uuid}
      false -> []
    end
  end

  @doc """
  Import the athlete's starred segments from Strava.
  """
  def import_starred_segments(%Athlete{} = athlete, starred_segments) do
    import_new_starred_segments(athlete, starred_segments) ++
      remove_old_starred_segments(athlete, starred_segments)
  end

  # state mutators

  def apply(%Athlete{} = athlete, %AthleteImported{} = athlete_imported) do
    %Athlete{
      athlete
      | athlete_uuid: athlete_imported.athlete_uuid,
        strava_id: athlete_imported.strava_id,
        firstname: athlete_imported.firstname,
        lastname: athlete_imported.lastname,
        profile: athlete_imported.profile,
        city: athlete_imported.city,
        country: athlete_imported.country,
        gender: athlete_imported.gender,
        email: athlete_imported.email,
        state: :imported
    }
  end

  def apply(%Athlete{club_memberships: club_memberships} = athlete, %AthleteJoinedClub{
        club_uuid: club_uuid
      }) do
    %Athlete{athlete | club_memberships: MapSet.put(club_memberships, club_uuid)}
  end

  def apply(%Athlete{club_memberships: club_memberships} = athlete, %AthleteLeftClub{
        club_uuid: club_uuid
      }) do
    %Athlete{athlete | club_memberships: MapSet.delete(club_memberships, club_uuid)}
  end

  def apply(%Athlete{starred_segments: starred_segments} = athlete, %AthleteStarredStravaSegment{
        strava_segment_id: strava_segment_id
      }) do
    %Athlete{athlete | starred_segments: MapSet.put(starred_segments, strava_segment_id)}
  end

  def apply(
        %Athlete{starred_segments: starred_segments} = athlete,
        %AthleteUnstarredStravaSegment{strava_segment_id: strava_segment_id}
      ) do
    %Athlete{athlete | starred_segments: MapSet.delete(starred_segments, strava_segment_id)}
  end

  def apply(%Athlete{} = athlete, %AthleteRenamed{firstname: firstname, lastname: lastname}),
    do: %Athlete{athlete | firstname: firstname, lastname: lastname}

  def apply(%Athlete{} = athlete, %AthleteEmailChanged{email: email}),
    do: %Athlete{athlete | email: email}

  def apply(%Athlete{} = athlete, %AthleteProfileChanged{profile: profile}),
    do: %Athlete{athlete | profile: profile}

  def apply(%Athlete{} = athlete, %AthleteGenderChanged{gender: gender}),
    do: %Athlete{athlete | gender: gender}

  def apply(%Athlete{} = athlete, _event), do: athlete

  ## private helpers

  defp is_club_member?(%Athlete{club_memberships: club_memberships}, club_uuid) do
    MapSet.member?(club_memberships, club_uuid)
  end

  defp join_new_clubs(%Athlete{} = athlete, club_uuids) do
    %Athlete{athlete_uuid: athlete_uuid, firstname: firstname, lastname: lastname, gender: gender} =
      athlete

    club_uuids
    |> Enum.reject(&is_club_member?(athlete, &1))
    |> Enum.map(fn club_uuid ->
      %AthleteJoinedClub{
        athlete_uuid: athlete_uuid,
        club_uuid: club_uuid,
        firstname: firstname,
        lastname: lastname,
        gender: gender
      }
    end)
  end

  defp leave_old_clubs(%Athlete{} = athlete, club_uuids) do
    %Athlete{athlete_uuid: athlete_uuid, club_memberships: existing_clubs} = athlete

    existing_clubs
    |> Enum.reject(fn club_uuid -> Enum.member?(club_uuids, club_uuid) end)
    |> Enum.map(fn club_uuid ->
      %AthleteLeftClub{
        athlete_uuid: athlete_uuid,
        club_uuid: club_uuid
      }
    end)
  end

  defp import_new_starred_segments(
         %Athlete{athlete_uuid: athlete_uuid} = athlete,
         starred_segments
       ) do
    starred_segments
    |> Enum.reject(fn starred_segment -> starred_segment.private end)
    |> Enum.reject(&is_starred_segment?(athlete, &1))
    |> Enum.map(fn starred_segment ->
      %AthleteStarredStravaSegment{
        athlete_uuid: athlete_uuid,
        strava_segment_id: starred_segment.id,
        name: starred_segment.name,
        distance_in_metres: starred_segment.distance,
        average_grade: starred_segment.average_grade,
        maximum_grade: starred_segment.maximum_grade,
        elevation_high: starred_segment.elevation_high,
        elevation_low: starred_segment.elevation_low,
        start_latlng: starred_segment.start_latlng,
        end_latlng: starred_segment.end_latlng,
        climb_category: starred_segment.climb_category,
        city: starred_segment.city,
        state: starred_segment.state,
        country: starred_segment.country
      }
    end)
  end

  defp remove_old_starred_segments(
         %Athlete{athlete_uuid: athlete_uuid, starred_segments: existing_starred_segments},
         starred_segments
       ) do
    starred_segment_strava_ids = pluck(starred_segments, :id)

    existing_starred_segments
    |> Enum.reject(fn strava_segment_id ->
      Enum.member?(starred_segment_strava_ids, strava_segment_id)
    end)
    |> Enum.map(fn strava_segment_id ->
      %AthleteUnstarredStravaSegment{
        athlete_uuid: athlete_uuid,
        strava_segment_id: strava_segment_id
      }
    end)
  end

  defp is_starred_segment?(%Athlete{starred_segments: starred_segments}, segment) do
    MapSet.member?(starred_segments, segment.id)
  end

  defp renamed(%Athlete{firstname: firstname, lastname: lastname}, %ImportAthlete{
         firstname: firstname,
         lastname: lastname
       }),
       do: nil

  defp renamed(%Athlete{athlete_uuid: athlete_uuid}, %ImportAthlete{
         firstname: firstname,
         lastname: lastname
       }) do
    %AthleteRenamed{
      athlete_uuid: athlete_uuid,
      firstname: firstname,
      lastname: lastname,
      fullname: fullname(firstname, lastname)
    }
  end

  defp email_changed(%Athlete{}, %ImportAthlete{email: nil}), do: nil
  defp email_changed(%Athlete{email: email}, %ImportAthlete{email: email}), do: nil

  defp email_changed(%Athlete{athlete_uuid: athlete_uuid}, %ImportAthlete{email: email}) do
    %AthleteEmailChanged{athlete_uuid: athlete_uuid, email: email}
  end

  defp profile_changed(%Athlete{profile: profile}, %ImportAthlete{profile: profile}), do: nil

  defp profile_changed(%Athlete{athlete_uuid: athlete_uuid}, %ImportAthlete{profile: profile}) do
    %AthleteProfileChanged{athlete_uuid: athlete_uuid, profile: profile}
  end

  defp gender_changed(%Athlete{gender: gender}, %ImportAthlete{gender: gender}), do: nil

  defp gender_changed(%Athlete{}, %ImportAthlete{gender: gender}) when gender in [nil, ""],
    do: nil

  defp gender_changed(%Athlete{} = athlete, %ImportAthlete{} = command) do
    %Athlete{athlete_uuid: athlete_uuid} = athlete
    %ImportAthlete{gender: gender} = command

    %AthleteGenderChanged{athlete_uuid: athlete_uuid, gender: gender}
  end

  defp fullname(firstname, lastname), do: "#{String.trim(firstname)} #{String.trim(lastname)}"
end
