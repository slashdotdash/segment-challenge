defmodule SegmentChallengeWeb.PageControllerTest do
  use SegmentChallengeWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Segment Challenge"
  end
end
