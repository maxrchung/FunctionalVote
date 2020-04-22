defmodule FunctionalVoteWeb.VoteController do
  use FunctionalVoteWeb, :controller

  alias FunctionalVote.Votes
  alias FunctionalVote.Polls

  action_fallback FunctionalVoteWeb.FallbackController

  @doc """
  Registers a new vote

  POST /vote
  @param: vote_params - contains "poll_id", and "choices"
  @return: No body, just a 201 Created status
  """
  def create(conn, vote_params) do
    IO.puts("[VoteCtrl] Submit vote")
    # Add remote IP to vote_params for multiple vote validation
    # https://stackoverflow.com/a/45284462/13183186
    ip_address = (conn.remote_ip |> :inet_parse.ntoa |> to_string())
    vote_params = Map.put(vote_params, "ip_address", ip_address)

    case Votes.create_vote(vote_params) do
      :ok ->
        {_, winner} = vote_params["poll_id"]
                         |> Votes.get_votes()
                         |> Polls.instant_runoff(vote_params["poll_id"], true)
        if (winner === :error) do
          send_resp(conn, :created, "Created poll but was unable to save winner to DB")
        else
          send_resp(conn, :created, "")
        end

      :id_error ->
        send_resp(conn, :unprocessable_entity, "Invalid poll ID")
      :multiple_votes_error ->
        send_resp(conn, :unprocessable_entity, "Multiple votes from the same IP address are not allowed for this poll")
      :empty_choices_error ->
        send_resp(conn, :unprocessable_entity, "Received no votes")
      :non_integer_rank_error ->
        send_resp(conn, :unprocessable_entity, "Received a vote with a non-integer rank")
      :available_choices_error ->
        send_resp(conn, :unprocessable_entity, "Received a choice that does not exist in this poll")
      :duplicate_rank_error ->
        send_resp(conn, :unprocessable_entity, "Received votes with duplicate ranks")
      :submission_timeout_error ->
        send_resp(conn, :unprocessable_entity, "Too many vote submissions have been made, please try again later")
      :recaptcha_error ->
        send_resp(conn, :unprocessable_entity, "reCAPTCHA verification failed")
      _ ->
        send_resp(conn, :internal_server_error, "")
    end
  end

end
