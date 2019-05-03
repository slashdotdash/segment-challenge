defmodule SegmentChallengeWeb.API.CommandView do
  use SegmentChallengeWeb, :view

  def render("dispatch.json", %{errors: errors}) do
    %{errors: Enum.map(errors, &to_json/1)}
  end

  defp to_json({:error, field, _type, message}) do
    %{
      name: field,
      message: message
    }
  end
end
