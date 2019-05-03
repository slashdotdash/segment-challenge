defmodule SegmentChallengeWeb.Plugs.ExcludeLayoutForAjaxRequest do
  use Phoenix.Controller, namespace: SegmentChallengeWeb
  
  def init(options), do: options

  def call(%Plug.Conn{req_headers: request_headers} = conn, _opts) do
    case Enum.member?(request_headers, {"x-requested-with", "XMLHttpRequest"}) do
      true -> put_layout(conn, false)
      false -> conn
    end
  end
end
