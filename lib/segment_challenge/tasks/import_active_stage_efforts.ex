defmodule SegmentChallenge.Tasks.ImportActiveStageEfforts do
  @moduledoc """
  Import stage efforts for active stages, or past stages which have not yet
  been approved.
  """

  use Timex

  require Logger

  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Stages.StageEffortImporter
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Repo

  def execute do
    for %StageProjection{} = stage <- Repo.all(active_stages_query()) do
      %StageProjection{stage_uuid: stage_uuid, name: name} = stage

      Logger.debug(fn ->
        "Importing stage efforts for stage #{inspect(name)} (#{inspect(stage_uuid)})"
      end)

      :ok = StageEffortImporter.execute(stage)
    end

    :ok
  end

  defp active_stages_query do
    from(
      s in StageProjection,
      where: s.status == "active" or (s.status == "past" and s.approved == false),
      order_by: [asc: s.refreshed_at]
    )
  end
end
