defmodule FunctionalVoteWeb.PollController do
  use FunctionalVoteWeb, :controller

  alias FunctionalVote.Polls
  alias FunctionalVote.Polls.Poll

  action_fallback FunctionalVoteWeb.FallbackController

  @doc """
  Creates a new poll

  POST /poll
  @param: poll_params - contains "title", and "choices"
  @return: Poll information as JSON
  """
  def create(conn, poll_params) do
    IO.puts("[PollCtrl] Create poll")
    with {:ok, %Poll{} = poll} <- Polls.create_poll(poll_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.poll_path(conn, :show, poll))
      |> show(%{"id" => poll.id})
    end
  end

  @doc """
  Gets all information about a poll

  GET /poll/:id
  @param: id - poll id
  @return: Poll information as JSON
  """
  def show(conn, %{"id" => id}) do
    IO.puts("[PollCtrl] Get poll data")
    poll = Polls.get_poll_data!(id)
    render(conn, "show.json", poll: poll)
  end

  def update(conn, %{"id" => id, "poll" => poll_params}) do
    poll = Polls.get_poll!(id)

    with {:ok, %Poll{} = poll} <- Polls.update_poll(poll, poll_params) do
      render(conn, "show.json", poll: poll)
    end
  end

  def delete(conn, %{"id" => id}) do
    poll = Polls.get_poll!(id)

    with {:ok, %Poll{}} <- Polls.delete_poll(poll) do
      send_resp(conn, :no_content, "")
    end
  end
end
