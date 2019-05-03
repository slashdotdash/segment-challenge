defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Stages.StageCompetitorProcessManager do
  alias SegmentChallenge.Stages.StageCompetitorProcessManager
  alias SegmentChallenge.Stages.StageCompetitorProcessManager.ChallengeStage
  alias SegmentChallenge.Stages.StageCompetitorProcessManager.Competitor

  def decode(%StageCompetitorProcessManager{} = pm) do
    %StageCompetitorProcessManager{
      active_stage: active_stage,
      competitors: competitors,
      stages: stages
    } = pm

    active_stage =
      case active_stage do
        nil -> nil
        stage -> struct(ChallengeStage, stage)
      end

    competitors = Enum.map(competitors, &struct(Competitor, &1))
    stages = Enum.map(stages, &struct(ChallengeStage, &1))

    %StageCompetitorProcessManager{
      pm
      | active_stage: active_stage,
        competitors: competitors,
        stages: stages
    }
  end
end
