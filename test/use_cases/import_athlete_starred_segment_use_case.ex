defmodule SegmentChallenge.UseCases.ImportAthleteStarredSegmentUseCase do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.Strava

  alias SegmentChallenge.Commands.ImportAthleteStarredStravaSegments
  alias SegmentChallenge.Events.{AthleteStarredStravaSegment, AthleteUnstarredStravaSegment}
  alias SegmentChallenge.Router

  def import_starred_segments(context) do
    use_cassette "athlete/import_starred_segments##{context[:athlete_uuid]}",
      match_requests_on: [:query] do
      :ok =
        Router.dispatch(%ImportAthleteStarredStravaSegments{
          athlete_uuid: context[:athlete_uuid],
          starred_segments: starred_segments()
        })
    end

    wait_for_event(AthleteStarredStravaSegment, fn event ->
      event.athlete_uuid == context[:athlete_uuid]
    end)

    :ok
  end

  def import_single_starred_segment(context) do
    use_cassette "athlete/import_single_starred_segment##{context[:athlete_uuid]}",
      match_requests_on: [:query] do
      :ok =
        Router.dispatch(%ImportAthleteStarredStravaSegments{
          athlete_uuid: context[:athlete_uuid],
          starred_segments: starred_segments()
        })
    end

    wait_for_event(AthleteUnstarredStravaSegment, fn event ->
      event.athlete_uuid == context[:athlete_uuid]
    end)

    :ok
  end
end
