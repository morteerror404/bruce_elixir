defmodule BruceElixirWeb.Router do
  use BruceElixirWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, {BruceElixirWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", BruceElixirWeb do
    pipe_through :browser
    live "/", BuilderLive
    get "/firmware/download", FirmwareController, :download
  end
end
