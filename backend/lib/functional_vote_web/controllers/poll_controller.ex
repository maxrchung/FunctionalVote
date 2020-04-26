defmodule FunctionalVoteWeb.PollController do
  use FunctionalVoteWeb, :controller

  require Logger
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
    Logger.debug("[PollCtrl] Create poll")
    # Add remote IP to poll_params for time out validation
    # https://stackoverflow.com/a/45284462/13183186
    ip_address = (conn.remote_ip |> :inet_parse.ntoa |> to_string())
    poll_params = Map.put(poll_params, "ip_address", ip_address)

    case Polls.create_poll(poll_params) do
      {:ok, %Poll{} = poll} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.poll_path(conn, :show, poll))
        |> show(%{"poll_id" => poll.poll_id})
      :no_title_error ->
        send_resp(conn, :unprocessable_entity, "No question provided")
      :max_title_error ->
        send_resp(conn, :unprocessable_entity, "Question cannot be greater than 100 characters")
      :no_choices_error ->
        send_resp(conn, :unprocessable_entity, "No choices provided")
      :max_choices_error ->
        send_resp(conn, :unprocessable_entity, "Cannot provide more than 100 choices")
      :duplicate_choices_error ->
        send_resp(conn, :unprocessable_entity, "Duplicate choices cannot be provided")
      :max_choice_error ->
        send_resp(conn, :unprocessable_entity, "Choice cannot be greater than 100 characters")
      :submission_timeout_error ->
        send_resp(conn, :unprocessable_entity, "Too many poll requests have been made, please try again later")
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
  def show(conn, %{"poll_id" => poll_id}) do
    Logger.debug("[PollCtrl] Get poll data")
    poll = Polls.get_poll_data!(poll_id)
    render(conn, "show.json", poll: poll)
  end

end
