defmodule SegmentChallenge.Strava.CacheTest do
  use SegmentChallenge.StorageCase

  alias SegmentChallenge.Strava.Cache

  @moduletag :integration

  describe "strava request cache" do
    test "should request on cache miss" do
      activity = activity_factory(2_117_432_519)

      assert {:ok, ^activity} = cached_request(5_704_447, activity)

      assert_receive :requested
    end

    test "should not request on cache hit" do
      activity = activity_factory(2_117_432_519)

      assert {:ok, ^activity} = cached_request(5_704_447, activity)
      assert {:ok, ^activity} = cached_request(5_704_447, activity)

      assert_receive :requested
      refute_receive :requested
    end

    test "should cache by identity" do
      activity1 = activity_factory(1)
      activity2 = activity_factory(2)

      assert {:ok, ^activity1} = cached_request(1, activity1)
      assert {:ok, ^activity2} = cached_request(2, activity2)
      assert {:ok, ^activity1} = cached_request(1, activity1)
      assert {:ok, ^activity2} = cached_request(2, activity2)

      assert_receive :requested
      assert_receive :requested
      refute_receive :requested
    end

    test "should purge on cache" do
      activity1 = activity_factory(2_117_432_519)
      activity2 = activity_factory(2_117_432_519)

      assert {:ok, ^activity1} = cached_request(5_704_447, activity1)
      assert_receive :requested

      :ok = Cache.purge(5_704_447, Strava.DetailedActivity)

      assert {:ok, ^activity2} = cached_request(5_704_447, activity2)
      assert {:ok, ^activity2} = cached_request(5_704_447, activity2)

      assert_receive :requested
      refute_receive :requested
    end
  end

  defp activity_factory(activity_id) do
    %Strava.DetailedActivity{
      id: activity_id,
      athlete: %Strava.MetaAthlete{id: 5_704_447},
      start_date: DateTime.from_naive!(~N[2019-02-08 15:34:00], "Etc/UTC"),
      start_date_local: DateTime.from_naive!(~N[2019-02-08 15:34:00], "Etc/UTC"),
      segment_efforts: [
        %Strava.DetailedSegmentEffort{
          id: 1,
          athlete: %Strava.MetaAthlete{id: 5_704_447},
          start_date: DateTime.from_naive!(~N[2019-02-08 15:34:00], "Etc/UTC"),
          start_date_local: DateTime.from_naive!(~N[2019-02-08 15:34:00], "Etc/UTC"),
          distance: 1234.5
        }
      ]
    }
  end

  defp cached_request(id, response) do
    Cache.cached(id, Strava.DetailedActivity, fn ->
      send(self(), :requested)

      {:ok, response}
    end)
  end
end
