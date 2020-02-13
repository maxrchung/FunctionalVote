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


  ## Examples

      iex> get_votes(123)
      %Vote{}

  """
  def get_votes(id) do
    # todo: finish
    votes = Repo.get_by(Votes, poll_id: id)
            |> group_votes_by_user()
    votes
  end

  defp group_votes_by_user(raw_votes) do
    # todo: finish
    raw_votes
  end

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
      user_id = Repo.one(query) || 1  # Use 1 if nil is returned (i.e. no votes found)
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
      :error
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
