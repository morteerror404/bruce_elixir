# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1782266351"

config :phoenix, :json_library, Jason

config :bruce_elixir, BruceElixirWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  secret_key_base: "lA0Kk81TYgcfn6VBUGLT8qQIIJNnKgyfT51JG43o0ADQ5mdq0+91lmT9ivbNDB3D1upxGweqPCPoIgciv8eE6A==",
  render_errors: [formats: [html: BruceElixirWeb.ErrorHTML, json: BruceElixirWeb.ErrorJSON]],
  pubsub_server: BruceElixir.PubSub,
  live_view: [signing_salt: "bruce_salt"]

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end

if File.exists?("config/nerves_features.exs") do
  import_config "nerves_features.exs"
end
