defmodule BruceElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        BruceElixir.PubSub,
        BruceElixir.BuildHistory
      ] ++ target_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BruceElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  if Mix.target() == :host do
    defp target_children() do
      [
        {BruceElixirWeb.Endpoint, []}
      ]
    end
  else
    defp target_children() do
      []
    end
  end
end
