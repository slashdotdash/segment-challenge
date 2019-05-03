defmodule SegmentChallengeWeb.Builders.UUIDHelper do
  def assign_uuid(params, key) do
    Map.put(params, key, UUID.uuid4)
  end
end
