defmodule SegmentChallenge.Strava.StravaGatewayTest do
  use SegmentChallenge.StorageCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import SegmentChallenge.UseCases.Strava

  alias SegmentChallenge.Strava.Gateway

  @moduletag :integration

  describe "strava gateway" do
    test "get activity" do
      use_cassette "strava/activities/2048109689", match_requests_on: [:query] do
        client = strava_client()

        assert {:ok, %Strava.DetailedActivity{id: 2_048_109_689}} =
                 Gateway.get_activity(client, 2_048_109_689)
      end
    end

    test "get cached activity" do
      use_cassette "strava/activities/2048109689", match_requests_on: [:query] do
        client = strava_client()

        assert {:ok, %Strava.DetailedActivity{id: 2_048_109_689}} =
                 Gateway.get_activity(client, 2_048_109_689)

        assert {:ok, %Strava.DetailedActivity{id: 2_048_109_689} = activity} =
                 Gateway.get_activity(client, 2_048_109_689)

        assert length(activity.best_efforts) == 7
        assert activity.start_date == DateTime.from_naive!(~N[2019-01-01 10:48:41], "Etc/UTC")
      end
    end

    test "get deleted activity" do
      use_cassette "strava/activities/2117432519", match_requests_on: [:query] do
        client = strava_client()

        assert {:error, :activity_not_found} = Gateway.get_activity(client, 2_117_432_519)
      end
    end
  end
end
