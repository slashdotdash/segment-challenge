defmodule SegmentChallenge.Tasks.Supervisor do
  use Supervisor

  alias SegmentChallenge.Tasks.{
    ApproveStageLeaderboards,
    ApproveChallengeLeaderboards,
    EmailSender,
    ImportActiveStageEfforts,
    StartActiveChallenge,
    StartActiveStage,
    EndPastStage,
    EndPastChallenge
  }

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init(_arg) do
    children = [
      schedule(ApproveStageLeaderboards, "@hourly"),
      schedule(ApproveChallengeLeaderboards, "@hourly"),
      schedule(EmailSender, "*/10 * * * *"),
      schedule(ImportActiveStageEfforts, "0 */4 * * *"),
      schedule(StartActiveChallenge, "@hourly"),
      schedule(StartActiveStage, "@hourly"),
      schedule(EndPastStage, "@hourly"),
      schedule(EndPastChallenge, "@hourly")
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp schedule(module, cron) do
    %{
      id: module,
      start: {SchedEx, :run_every, [module, :execute, [], cron]}
    }
  end
end
