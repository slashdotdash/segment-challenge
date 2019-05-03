defmodule SegmentChallenge.Jobs.UpdateStravaActivity do
  @moduledoc """
  Replace an athlete's activity from Strava after it has been updated.
  """

  @behaviour Rihanna.Job

  require Logger

  import SegmentChallenge.Jobs.RetryJob

  alias SegmentChallenge.Stages.StageActivityImporter
  alias SegmentChallenge.Strava.Cache

  def perform(args) do
    strava_activity_id = Keyword.fetch!(args, :strava_activity_id)

    Cache.purge(strava_activity_id, Strava.DetailedActivity)

    StageActivityImporter.execute(args)
  end

  def after_error(error, args) do
    Rollbax.report_message(:error, "Update Strava activity failed", %{
      "error" => inspect(error),
      "args" => inspect(args)
    })

    retry(__MODULE__, args)
  end
end
