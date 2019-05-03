defmodule SegmentChallengeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use SegmentChallengeWeb, :controller
      use SegmentChallengeWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: SegmentChallengeWeb

      import Plug.Conn
      import SegmentChallengeWeb.Router.Helpers
      import SegmentChallengeWeb.Gettext
      import SegmentChallengeWeb.ControllerHelpers
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/segment_challenge_web/templates",
        namespace: SegmentChallengeWeb

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      use SegmentChallengeWeb.Helpers.Defaults

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      import SegmentChallengeWeb.Router.Helpers
      import SegmentChallengeWeb.ErrorHelpers
      import SegmentChallengeWeb.Helpers.AthleteHelpers
      import SegmentChallengeWeb.Helpers.DateTimeHelpers
      import SegmentChallengeWeb.Helpers.EnvironmentHelpers
      import SegmentChallengeWeb.Helpers.FormHelpers
      import SegmentChallengeWeb.Helpers.GoalHelpers
      import SegmentChallengeWeb.Helpers.NavigationHelpers
      import SegmentChallengeWeb.Helpers.NumberHelpers
      import SegmentChallengeWeb.Helpers.ProgressHelpers
      import SegmentChallengeWeb.Helpers.StravaUrlHelpers
      import SegmentChallengeWeb.Helpers.TextHelpers
      import SegmentChallengeWeb.Helpers.UnitHelpers
      import SegmentChallengeWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      import SegmentChallengeWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
