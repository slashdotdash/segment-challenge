defmodule SegmentChallengeWeb.Helpers.EnvironmentHelpers do
  def production? do
    environment() == :prod
  end

  def dev? do
    environment() == :dev
  end

  def test? do
    environment() == :test
  end

  def environment do
    Application.get_env(:segment_challenge, :environment_name)
  end
end
