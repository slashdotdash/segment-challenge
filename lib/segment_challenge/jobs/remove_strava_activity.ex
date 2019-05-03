defmodule SegmentChallenge.Jobs.RemoveStravaActivity do
  @moduledoc """
  Remove a deleted activity from the Strava cache and any related stage efforts.
  """

  @behaviour Rihanna.Job

  require Logger

  alias SegmentChallenge.Stages.StageActivityRemover
  alias SegmentChallenge.Strava.Cache

  def perform(args) do
    strava_activity_id = Keyword.fetch!(args, :strava_activity_id)

    Cache.purge(strava_activity_id, Strava.DetailedActivity)

    StageActivityRemover.execute(args)
  end

  def after_error(error, args) do
    Rollbax.report_message(:error, "Remove Strava activity failed", %{
      "error" => inspect(error),
      "args" => inspect(args)
    })
  end
end
