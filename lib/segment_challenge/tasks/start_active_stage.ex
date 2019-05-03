defmodule SegmentChallenge.Tasks.StartActiveStage do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Stages.Stage.Commands.StartStage
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Router
  alias SegmentChallenge.Repo

  def execute do
    utc_now() |> execute()
  end

  def execute(now) do
    now
    |> stages_to_start()
    |> Repo.all()
    |> Enum.each(&start_stage/1)
  end

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()

  defp stages_to_start(now) do
    from(s in StageProjection,
      where: s.status == "upcoming" and s.start_date <= ^now
    )
  end

  defp start_stage(stage) do
    Router.dispatch(%StartStage{
      stage_uuid: stage.stage_uuid
    })
  end
end
