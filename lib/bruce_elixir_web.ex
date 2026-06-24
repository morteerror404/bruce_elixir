defmodule BruceElixirWeb do
  @moduledoc false

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Phoenix.LiveView.Router
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView
      import Phoenix.HTML
      import Phoenix.Component
      import BruceElixirWeb.Components
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      import Phoenix.HTML
      import Phoenix.Component
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: []

      import Plug.Conn
      import Phoenix.HTML
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
