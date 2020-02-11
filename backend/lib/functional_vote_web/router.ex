defmodule FunctionalVoteWeb.Router do
  use FunctionalVoteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    # plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug CORSPlug, origin: "http://localhost:3000"
    plug :accepts, ["json"]
  end

  scope "/", FunctionalVoteWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/poll", PageController, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", FunctionalVoteWeb do
  #   pipe_through :api
  # end
end
