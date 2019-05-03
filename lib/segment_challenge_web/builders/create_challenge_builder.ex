defmodule SegmentChallengeWeb.CreateChallengeBuilder do
  import SegmentChallengeWeb.Builders.{CurrentAthleteHelper, DateTimeHelper, UUIDHelper}

  alias SegmentChallenge.Commands.CreateChallenge
  alias SegmentChallenge.Projections.Clubs.ClubProjection
  alias SegmentChallenge.Repo

  def new(conn, _params) do
    %CreateChallenge{
      created_by_athlete_uuid: current_athlete_uuid(conn),
      created_by_athlete_name: current_athlete_name(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_uuid(:challenge_uuid)
    |> assign_hosted_by_club()
    |> assign_created_by_athlete_uuid(conn)
    |> assign_created_by_athlete_name(conn)
    |> parse_date_time("start_date")
    |> parse_date_time("start_date_local")
    |> parse_date_time("end_date")
    |> parse_date_time("end_date_local")
    |> parse_float("goal")
    |> parse_stages()
    |> CreateChallenge.new()
  end

  def assign_hosted_by_club(%{"hosted_by_club_uuid" => hosted_by_club_uuid} = params) do
    case Repo.get(ClubProjection, hosted_by_club_uuid) do
      nil ->
        params

      club ->
        params
        |> Map.put(:hosted_by_club_name, club.name)
        |> Map.put(:private, club.private)
    end
  end

  def assign_hosted_by_club(params), do: params

  def assign_created_by_athlete_uuid(params, conn),
    do: Map.put(params, :created_by_athlete_uuid, current_athlete_uuid(conn))

  def assign_created_by_athlete_name(params, conn),
    do: Map.put(params, :created_by_athlete_name, current_athlete_name(conn))

  def parse_float(params, key) do
    Map.update(params, key, nil, fn value ->
      case Float.parse(value) do
        {float, ""} -> float
        _ -> value
      end
    end)
  end

  def parse_stages(params) do
    Map.update(params, "stages", [], fn stages ->
      Enum.map(stages, fn stage ->
        stage
        |> parse_date_time("start_date")
        |> parse_date_time("start_date_local")
        |> parse_date_time("end_date")
        |> parse_date_time("end_date_local")
      end)
    end)
  end
end
