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
    case Polls.create_poll(poll_params) do
      {:ok, %Poll{} = poll} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.poll_path(conn, :show, poll))
        |> show(%{"id" => poll.id})
      :duplicate_choices_error ->
        send_resp(conn, :unprocessable_entity, "Duplicate choices provided")
      :title_error ->
        send_resp(conn, :unprocessable_entity, "No title provided")
      _ ->
        send_resp(conn, :internal_server_error, "")
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

end
