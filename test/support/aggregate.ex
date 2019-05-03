defmodule SegmentChallenge.Aggregate do
  def evolve(aggregate, events) do
    Enum.reduce(List.wrap(events), aggregate, &aggregate.__struct__.apply(&2, &1))
  end
end
