defmodule FunctionalVoteWeb.VoteController do
  use FunctionalVoteWeb, :controller

  alias FunctionalVote.Votes

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
      :ok -> send_resp(conn, :created, "")
      :id_error -> send_resp(conn, :internal_server_error, "Invalid poll ID")
      _ -> send_resp(conn, :internal_server_error, "")
    end
  end

end
