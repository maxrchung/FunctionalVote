defmodule FunctionalVote.Polls do
  @moduledoc """
  The Polls context.
  """

  import Ecto.Query, warn: false
  alias FunctionalVote.Repo

  alias FunctionalVote.Polls.Poll

  alias FunctionalVote.Votes

  @doc """
  Instant-runoff voting (IRV) algorithm
  @param votes - votes data from DB
  @param poll_id - poll_id
  @param write_winner - write the calculated winner to DB with the provided poll (false => don't write)
  @return {raw_tallies, irv_tallies} - raw_tallies before IRV, tallies after IRV
  """
  def instant_runoff!(votes, poll_id, write_winner \\ false) do
    num_users = map_size(votes)
    IO.puts("[PollCtx] Starting IRV algorithm with following votes by #{num_users} users:")
    IO.inspect(votes)
    tallies_by_choice = Map.values(votes)
                        |> List.zip()
                        |> List.first()
                        |> Tuple.to_list()
                        |> Enum.frequencies()
    tallies_by_count = Enum.group_by(tallies_by_choice, fn {_, value} -> value end, fn {key, _} -> key end)
    IO.puts("[PollCtx] Raw tallies by count:")
    IO.inspect(tallies_by_count)
    initial_max_count = Map.keys(tallies_by_count)
                        |> Enum.max()
    IO.puts("initial_max_count: #{initial_max_count}")
    winner = tallies_by_count[initial_max_count]
    if (initial_max_count <= num_users / 2) do
      IO.puts("[PollCtx] No simple majority, continuing IRV algorithm")
      # {tallies_by_choice, tallies_by_count} = instant_runoff_recurse(tallies_by_choice, tallies_by_count)
      if (length(winner) > 1) do
        if (write_winner) do
          IO.puts("[PollCtx] Result is a tie, randomizing winner and saving to database")
          winner = tallies_by_count[Map.keys(tallies_by_count) |> Enum.max()] |> Enum.random()
          poll = get_poll!(poll_id)
          cs = Ecto.Changeset.change poll, winner: winner
          case Repo.update cs do
          {:ok, cs} ->
              IO.puts("[PollCtx] Saved winner to DB")
            {:error, changeset} -> 
              IO.puts("[PollCtx] Unable to save winner to DB:")
              IO.inspect(changeset)
          end
          {tallies_by_choice, tallies_by_choice, winner} # RETURN ENDPOINT
        else
          IO.puts("[PollCtx] Result is a tie, getting previously-randomized winner from database")
          query = from p in Poll,
                  where: p.id == ^poll_id,
                  select: p.winner
          winner = Repo.one(query)
          {tallies_by_choice, tallies_by_choice, winner} # RETURN ENDPOINT
        end
      else
        {tallies_by_choice, tallies_by_choice, winner} # RETURN ENDPOINT
      end
    else
      IO.puts("[PollCtx] Simple majority reached, ending IRV algorithm")
      {tallies_by_choice, tallies_by_choice, winner} # RETURN ENDPOINT
    end
  end

  @doc """
  @param id
  @return true if the poll exists
  """
  def poll_exists?(id) do
    query = from p in Poll,
              where: p.id == ^id
    Repo.exists?(query)
  end

  @doc """
  Gets a single poll.
  Raises `Ecto.NoResultsError` if the Poll does not exist.
  """
  def get_poll!(id), do: Repo.get!(Poll, id)

  @doc """
  Gets poll data.

  Raises `Ecto.NoResultsError` if the Poll does not exist.

  ## Examples

      iex> get_poll!(123)
      %Poll{}

      iex> get_poll!(456)
      ** (Ecto.NoResultsError)

  """
  def get_poll_data!(id) do
    # todo: finish
    IO.puts("[PollCtx] Get poll data")
    poll = Repo.get!(Poll, id)
    votes = Votes.get_votes(id)
    if (map_size(votes) == 0) do
      IO.puts("[PollCtx] No votes in poll, returning empty tallies and winner")
      calculated = %{raw_tallies: nil, tallies: nil, winner: nil}
      Map.merge(poll, calculated) # RETURN ENDPOINT
    else
      {raw_tallies, irv_tallies, winner} = instant_runoff!(votes, String.to_integer(id))
      calculated = %{raw_tallies: raw_tallies, tallies: irv_tallies, winner: winner}
      Map.merge(poll, calculated) # RETURN ENDPOINT
    end
  end

  @doc """
  Creates a poll.

  ## Examples

      iex> create_poll(%{field: value})
      {:ok, %Poll{}}

      iex> create_poll(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_poll(attrs \\ %{}) do
    IO.puts("[PollCtx] Create poll")
    %Poll{}
    |> Poll.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a poll.

  ## Examples

      iex> update_poll(poll, %{field: new_value})
      {:ok, %Poll{}}

      iex> update_poll(poll, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_poll(%Poll{} = poll, attrs) do
    poll
    |> Poll.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a poll.

  ## Examples

      iex> delete_poll(poll)
      {:ok, %Poll{}}

      iex> delete_poll(poll)
      {:error, %Ecto.Changeset{}}

  """
  def delete_poll(%Poll{} = poll) do
    Repo.delete(poll)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking poll changes.

  ## Examples

      iex> change_poll(poll)
      %Ecto.Changeset{source: %Poll{}}

  """
  def change_poll(%Poll{} = poll) do
    Poll.changeset(poll, %{})
  end
end
