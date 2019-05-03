defmodule SegmentChallenge.Tasks.EndPastStage do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Stages.Stage.Commands.EndStage
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Router
  alias SegmentChallenge.Repo

  def execute do
    utc_now()
    |> stages_to_end()
    |> Repo.all()
    |> Enum.each(&end_stage/1)
  end

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()

  defp stages_to_end(now) do
    from(s in StageProjection,
      where: s.status == "active" and s.end_date <= ^now
    )
  end

  defp end_stage(stage) do
    Router.dispatch(%EndStage{stage_uuid: stage.stage_uuid})
  end
end
