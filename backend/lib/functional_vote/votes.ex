defmodule FunctionalVote.Votes do
  @moduledoc """
  The Votes context.
  """

  import Ecto.Query, warn: false
  alias FunctionalVote.Repo

  alias FunctionalVote.Polls
  alias FunctionalVote.Polls.Votes

  @doc """
  Gets all votes for a specified Poll.
  """
  def get_votes(poll_id) do
    # todo: finish
    query = from v in Votes,
            where: v.poll_id == ^poll_id,
            select: {v.user_id, v.rank, v.choice}
    # List of tuples sorted descending (highest user_id, highest rank / last choice first)
    # ex: [{1, 1, "a"}, {1, 0, "b"}, {0, 1, "b"}, {0, 0, "a"}]
    votes_list = Repo.all(query)
    # Get number of voters
    query = from v in Votes,
            where: v.poll_id == ^poll_id,
            select: max(v.user_id)
    max_user_id = Repo.one(query) || -1  # -1 indicates no voters
    IO.puts("[VotesCtx] Got #{length(votes_list)} votes from #{max_user_id + 1} voters")
    IO.inspect(votes_list)
    # Convert into list of %{:applied => 0, :ranks => %{0 => "a", ...}, :choices => %{"a" => 0, ...}}
    if (max_user_id !== -1) do
      IO.puts("TEST")
      a = Enum.group_by(votes_list, &elem(&1, 0), &Tuple.delete_at(&1, 0) |> Tuple.to_list())
      IO.inspect(a)
    #   cur_user = List.first(votes_list)
    #              |> Tuple.to_list()
    #              |> List.first()
    #   votes_list_to_return = []
    #   votes_list_by_user = [cur_user]
    #   Enum.each votes_list, fn {user_id, rank, choice} ->
    #       if (user_id != cur_user) do
    #         # New user_id detected, add votes_list_by_user to votes_list and reset
    #         IO.puts("[VotesCtx] Finished constructing list for user")
    #         IO.inspect(votes_list_by_user)
    #         List.insert_at(votes_list_to_return, -1, votes_list_by_user)
    #         votes_list_by_user = [user_id]
    #         cur_user = user_id
    #       end
    #       IO.puts("[VotesCtx] Added #{choice} for user #{cur_user}")
    #       List.insert_at(votes_list_by_user, -1, choice)
    #   end
    #   IO.inspect(votes_list_by_user)
    #   List.insert_at(votes_list_to_return, -1, votes_list_by_user)
    #   IO.puts("[VotesCtx] Finished votes_list")
    #   IO.inspect(votes_list_to_return)
    #   votes_list_to_return
    else
      []
    end
  end

  defp recurse_prepend_to_list([head | tail]) do
    recurse_prepend_to_list([head], [tail])
  end

  defp recurse_prepend_to_list(result, [head | tail]) do
    recurse_prepend_to_list([head | result], [tail])
  end

  defp recurse_prepend_to_list(result, []), do: result

  @doc """
  Creates a vote.

  ## Examples

      iex> create_vote(%{field: value})
      {:ok}

      iex> create_vote(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_vote(attrs \\ %{}) do
    poll_id = String.to_integer(attrs["poll_id"])
    if Polls.poll_exists?(poll_id) do
      IO.puts("[VoteCtx] Create vote in poll_id: #{poll_id}")
      # Determine user_id to use: max(user_id) + 1 in the table for this this poll_id
      query = from v in "votes",
              where: v.poll_id == ^poll_id,
              select: max(v.user_id) + 1
      user_id = Repo.one(query) || 0  # Use 0 if nil is returned (i.e. no votes found)
      IO.puts("[VoteCtx] Determined user_id: #{user_id}")
      # Parse out "choices" and insert an entry for each choice and rank
      choices = attrs["choices"]
      IO.puts("[VoteCtx] Got #{map_size(choices)} choices")
      Enum.each choices, fn {k, v} ->
        choice_map = %{"poll_id" => poll_id,
                      "user_id" => user_id,
                      "choice"  => k,
                      "rank"    => String.to_integer(v)}
        %Votes{}
          |> Votes.changeset(choice_map)
          |> Repo.insert()
      end
    else
      # Poll we are voting for does not exist
      IO.puts("[VoteCtx] poll_id #{poll_id} does not exist!")
      :id_error
    end
  end

  @doc """
  Updates a vote.

  ## Examples

      iex> update_vote(vote, %{field: new_value})
      {:ok, %Votes{}}

      iex> update_vote(vote, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_vote(%Votes{} = vote, attrs) do
    vote
    |> Votes.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a vote.

  ## Examples

      iex> delete_vote(vote)
      {:ok, %Votes{}}

      iex> delete_vote(vote)
      {:error, %Ecto.Changeset{}}

  """
  def delete_vote(%Votes{} = vote) do
    Repo.delete(vote)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vote changes.

  ## Examples

      iex> change_vote(vote)
      %Ecto.Changeset{source: %Votes{}}

  """
  def change_vote(%Votes{} = vote) do
    Votes.changeset(vote, %{})
  end
end
