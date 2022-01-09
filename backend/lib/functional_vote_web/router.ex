defmodule FunctionalVoteWeb.Router do
  use FunctionalVoteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug RemoteIp
  end

  pipeline :api do
    plug CORSPlug, origin: "http://localhost:3000"
    plug :accepts, ["json"]
  end

  scope "/", FunctionalVoteWeb do
    pipe_through :browser

    post "/poll", PollController, :create
    get "/poll/:poll_id", PollController, :show
    post "/vote", VoteController, :create
    get "/", HealthCheckController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", FunctionalVoteWeb do
  #   pipe_through :api
  # end
end
