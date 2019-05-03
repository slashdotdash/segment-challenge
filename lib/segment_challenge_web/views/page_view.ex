defmodule SegmentChallengeWeb.PageView do
  use SegmentChallengeWeb, :view

  def title("about.html", _assigns), do: "About - Segment Challenge"
  def title("privacy.html", _assigns), do: "Privacy policy - Segment Challenge"
  def title("cookies.html", _assigns), do: "Cookies - Segment Challenge"
  def title("terms.html", _assigns), do: "Terms and conditions - Segment Challenge"
end
