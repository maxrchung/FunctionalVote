defmodule FunctionalVoteWeb.PageController do
  use FunctionalVoteWeb, :controller

  alias FunctionalVote.Polls
  alias FunctionalVote.Polls.Poll

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, poll_params) do
    with {:ok, %Poll{} = poll} <- Polls.create_poll(poll_params) do
      IO.puts("[Create] Successfully created poll with id: #{poll.id}")
      send_resp(conn, :created, Integer.to_string(poll.id))
    end
  end

end
