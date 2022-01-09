defmodule FunctionalVoteWeb.HealthCheckController do
  use FunctionalVoteWeb, :controller

  action_fallback FunctionalVoteWeb.FallbackController

  @doc """
  Health check endpoint that always returns 200. It's used by AWS container service to
  see if this server is healthy and spin up a new container if needed.

  GET /
  @return: 200
  """
  def index(conn, _params) do
    send_resp(conn, :ok, "Health check good. Functional Vote backend is up and running. :)")
  end
end
