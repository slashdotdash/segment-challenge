defmodule SegmentChallenge.Jobs.ImportStravaActivity do
  @moduledoc """
  Import an athlete's activity from Strava if applicable for any active challenges.
  """

  @behaviour Rihanna.Job

  require Logger

  import SegmentChallenge.Jobs.RetryJob

  alias SegmentChallenge.Stages.StageActivityImporter

  def perform(args) do
    StageActivityImporter.execute(args)
  end

  def after_error(error, args) do
    Rollbax.report_message(:error, "Import Strava activity failed", %{
      "error" => inspect(error),
      "args" => inspect(args)
    })

    retry(__MODULE__, args)
  end
end
