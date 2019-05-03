defmodule SegmentChallengeWeb.StageActivityView do
  use SegmentChallengeWeb, :view

  def title("show.html", %{stage: stage}), do: stage.name <> " activity - Segment Challenge"
end
