defmodule FunctionalVote.Votes do
  @moduledoc """
  The Votes context.
  """

  import Ecto.Query, warn: false
  alias FunctionalVote.Repo

  alias FunctionalVote.Polls
  alias FunctionalVote.Polls.Votes

  @doc """
  Gets all votes for a specified Poll, grouped by user

  @param poll_id
  @return Map of lists, ex: %{0 => ["a", "b", "c"], 1 => ["c", "b", "a"]}
  """
  def get_votes(poll_id) do
    query = from v in Votes,
            where: v.poll_id == ^poll_id,
            select: {v.user_id, v.rank, v.choice}
    # List of tuples sorted ascending (lowest user_id, lowest rank / first choice first)
    # Ex: [{0, 0, "a"}, {0, 1, "b"}, {0, 2, "c"}, {1, 2, "a"}, {1, 1, "b"}, {1, 0, "c"}]
    votes_list = Repo.all(query)
                 |> Enum.sort()
    # Get number of voters
    query = from v in Votes,
            where: v.poll_id == ^poll_id,
            select: max(v.user_id)
    max_user_id = Repo.one(query) || -1  # -1 indicates no voters
    IO.puts("[VotesCtx] Got #{length(votes_list)} votes from #{max_user_id + 1} voters")
    # IO.inspect(votes_list)
    # Convert into list of %{0 => ["a", "b", "c"], 1 => ["c", "b", "a"]}
    if (max_user_id !== -1) do
      _votes_by_user = Enum.group_by(votes_list, &elem(&1, 0), &Tuple.to_list(&1) |> List.last()) # RETURN ENDPOINT
    else
      %{} # RETURN ENDPOINT
    end
  end

  @doc """
  Creates a vote.

  @param attrs : contains "poll_id" and "choices" (map of choices and ranks)
  @return {:ok}
  @return {:choices_error} Invalid choices provided (does not match choices of poll)
  @return {:id_error} Invalid poll ID provided
  """
  def create_vote(attrs \\ %{}) do
    poll_id = String.to_integer(attrs["poll_id"])
    if Polls.poll_exists?(poll_id) do
      available_choices = Polls.get_poll_choices(poll_id)
      IO.puts("[VoteCtx] Create vote in poll_id: #{poll_id}")
      # Determine user_id to use: max(user_id) + 1 in the table for this this poll_id
      query = from v in "votes",
              where: v.poll_id == ^poll_id,
              select: max(v.user_id) + 1
      user_id = Repo.one(query) || 0  # Use 0 if nil is returned (i.e. no votes found)
      IO.puts("[VoteCtx] Determined user_id: #{user_id}")
      # Parse out "choices" and insert an entry for each choice and rank
      choices = attrs["choices"]
      if (available_choices === Map.keys(choices) and
          Map.values(choices) === Enum.uniq(Map.values(choices))) do
        IO.puts("[VoteCtx] Got #{map_size(choices)} choices")
        Enum.each choices, fn {k, v} ->
          choice_map = %{"poll_id" => poll_id,
                        "user_id" => user_id,
                        "choice"  => k,
                        "rank"    => String.to_integer(v)}
          %Votes{}
            |> Votes.changeset(choice_map)
            |> Repo.insert() # RETURN ENDPOINT
        end
      else
        # Invalid choice(s) received
        IO.puts("[VoteCtx] Received invalid choices:")
        IO.inspect(Map.keys(choices))
        :choices_error # RETURN ENDPOINT
      end
    else
      # Poll we are voting for does not exist
      IO.puts("[VoteCtx] poll_id #{poll_id} does not exist!")
      :id_error # RETURN ENDPOINT
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
