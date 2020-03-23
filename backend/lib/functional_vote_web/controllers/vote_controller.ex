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
      :non_integer_rank_error ->
        send_resp(conn, :unprocessable_entity, "Received a vote with a non-integer rank")
      :available_choices_error ->
        send_resp(conn, :unprocessable_entity, "Received a choice that does not exist in this poll")
      :duplicate_rank_error ->
        send_resp(conn, :unprocessable_entity, "Received votes with duplicate ranks")
      _ ->
        send_resp(conn, :internal_server_error, "")
    end
  end

end
