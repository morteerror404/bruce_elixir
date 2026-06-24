defmodule BruceElixirWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :bruce_elixir

  socket "/live", Phoenix.LiveView.Socket

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, store: :cookie, key: "_bruce_key", signing_salt: "bruce_sess"
  plug BruceElixirWeb.Router
end
