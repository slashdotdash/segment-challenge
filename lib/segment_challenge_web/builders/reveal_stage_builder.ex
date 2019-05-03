defmodule SegmentChallengeWeb.RevealStageBuilder do
  alias SegmentChallenge.Stages.Stage.Commands.RevealStage

  def new(_conn, _params), do: %RevealStage{}
  def build(_conn, params), do: RevealStage.new(params)
end
