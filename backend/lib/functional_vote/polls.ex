defmodule FunctionalVote.Polls do
  @moduledoc """
  The Polls context.
  """

  import Ecto.Query, warn: false
  alias FunctionalVote.Repo

  alias FunctionalVote.Polls.Poll
  alias FunctionalVote.Polls.Results

  alias FunctionalVote.Votes
  
  @doc """
  Save the winner to the database
  @param poll_id - poll_id
  @param winner - winner to write
  """
  def write_winner(poll_id, winner) do
    poll = get_poll!(poll_id)
    cs = Ecto.Changeset.change poll, winner: winner
    case Repo.update cs do
      {:ok, _cs} ->
        IO.puts("[PollCtx] Writing winner to DB")
      {:error, changeset} -> 
        IO.puts("[PollCtx] Unable to write winner to DB:")
        IO.inspect(changeset)
    end
  end

  @doc """
  Retrieve the winner from the database
  @param poll_id - poll_id
  @return winner
  """
  def read_winner(poll_id) do
    IO.puts("[PollCtx] Reading winner from DB")
    query = from p in Poll,
            where: p.id == ^poll_id,
            select: p.winner
    _winner = Repo.one(query)
  end

  @doc """
  Save the tallies to the database
  @param poll_id
  @param talles_by_count
  """
  def write_round(poll_id, tallies_by_choice, round) do
    if (round != 0) do # Round 0 is just raw_tallies, no need to write it in DB
      IO.puts("[PollCtx] Writing round #{round} results to DB")
      Enum.each tallies_by_choice, fn {k, v} ->
        choice_map = %{poll_id: poll_id,
                      round: round,
                      choice: k, 
                      votes: v}
        %Results{}
          |> Results.changeset(choice_map)
          |> Repo.insert() # RETURN ENDPOINT
      end
    end
  end

  @doc """
  Clear the tallies in the database
  @param poll_id
  """
  def clear_rounds(poll_id) do
    IO.puts("[PollCtx] Clearing round results of poll id #{poll_id}")
    query = from r in Results,
            where: r.poll_id == ^poll_id
    Repo.delete_all(query)
  end

  @doc """
  Read the tallies from the database
  @param poll_id
  """
  def read_rounds(poll_id) do
    IO.puts("[PollCtx] Reading round results of poll id #{poll_id}")
    query = from r in Results,
            where: r.poll_id == ^poll_id,
            select: {r.round, r.choice, r.votes}
    data = Repo.all(query)
    _tallies_by_count = Enum.group_by(data,
                                     fn {round, _, _} -> round end,
                                     fn {_, choice, votes} -> {choice, votes} end)
                        |> Enum.map(fn {k, v} -> {k, Map.new(v)} end)
                        |> Map.new()
  end

  @doc """
  Instant-runoff voting (IRV) algorithm

  2 base cases marked with # BASE CASE ENDPOINT
  Recursion endpoint marked with # RETURN ENDPOINT

  @param votes - votes data from DB
  @param poll_id - poll_id
  @return {tallies_by_choice, winner}
  """
  def instant_runoff_recurse(votes, poll_id, round) do
    tallies_by_choice = Map.values(votes)
                        |> List.zip()
                        |> List.first()
                        |> Tuple.to_list()
                        |> Enum.frequencies()
    write_round(poll_id, tallies_by_choice, round)
    tallies_by_count = Enum.group_by(tallies_by_choice, fn {_, value} -> value end, fn {key, _} -> key end)
    num_users = Map.values(tallies_by_choice) |> Enum.sum()
    num_choices = Kernel.map_size(tallies_by_choice)
    max_count = Map.keys(tallies_by_count)
                |> Enum.max()
    winner = tallies_by_count[max_count] # Array of choice(s) with the most votes
    if (max_count <= num_users / 2) do
      IO.puts("[PollCtx] No majority, needed #{div(num_users, 2) + 1}")
      if (num_choices == 2) do
        winner = tallies_by_count[Map.keys(tallies_by_count) |> Enum.max()] |> Enum.random()
        IO.puts("[PollCtx] Result is a tie, randomized winner to be #{winner}")
        write_winner(poll_id, winner)
        {tallies_by_choice, winner} # BASE CASE ENDPOINT
      else
        # Eliminate loser (if there is a tie for last, randomly choose one)
        if (round == 0) do
          # Clear previous results for this poll_id as we are rerunning the algorithm
          clear_rounds(poll_id)
        end
        round = round + 1 # Round 1 = Tallies after first elimination
        loser = tallies_by_count[Map.keys(tallies_by_count) |> Enum.min()] |> Enum.random()
        IO.puts("[PollCtx] Eliminated #{loser} in round #{round}")
        votes = for {k, v} <- votes,
                into: %{},
                do: {k, 
                    if (List.first(v) == loser) do
                      [_head | tail] = v
                      tail
                    else
                      v
                    end
                }
        {tallies_by_choice, winner} = instant_runoff_recurse(votes, poll_id, round)
        # At this point, we will have already hit a base case and wrote the winner to DB
        {tallies_by_choice, winner} # RETURN ENDPOINT
      end
    else
      IO.puts("[PollCtx] Majority reached with #{winner} having #{max_count} votes")
      winner = List.first(winner)
      write_winner(poll_id, winner)
      {tallies_by_choice, winner} # BASE CASE ENDPOINT
    end
  end

  @doc """
  Instant-runoff voting (IRV) algorithm main entry point
  @param votes - votes data from DB
  @param poll_id - poll_id
  @param write_winner - write the calculated winner to DB with the provided poll (false => just read the winner)
  @return {raw_tallies, irv_tallies} - raw_tallies before IRV, tallies after IRV
  """
  def instant_runoff(votes, poll_id, write_winner \\ false) do
    IO.puts("[PollCtx] Starting IRV algorithm with the following votes:")
    IO.inspect(votes)
    raw_tallies = Map.values(votes)
                  |> List.zip()
                  |> List.first()
                  |> Tuple.to_list()
                  |> Enum.frequencies()
    tallies_by_count = Enum.group_by(raw_tallies, fn {_, value} -> value end, fn {key, _} -> key end)
    IO.puts("[PollCtx] Raw tallies by count:")
    IO.inspect(tallies_by_count)
    unless (write_winner) do
      # Just read the winner and return raw_tallies and winner
      winner = read_winner(poll_id)
      irv_tallies = read_rounds(poll_id)
      {raw_tallies, irv_tallies, winner} # RETURN ENDPOINT
    else
      {_, winner} = instant_runoff_recurse(votes, poll_id, 0)
      irv_tallies = read_rounds(poll_id)
      {raw_tallies, irv_tallies, winner} # RETURN ENDPOINT
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
  @param id, choice
  @return choices of the given poll id
  """
  def get_poll_choices(id) do
    query = from p in Poll,
              where: p.id == ^id,
              select: p.choices
    Repo.one(query)
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
    IO.puts("[PollCtx] Get poll data")
    poll = Repo.get!(Poll, id)
    votes = Votes.get_votes(id)
    if (map_size(votes) == 0) do
      IO.puts("[PollCtx] No votes in poll, returning empty tallies and winner")
      calculated = %{raw_tallies: nil, tallies: nil, winner: nil}
      Map.merge(poll, calculated) # RETURN ENDPOINT
    else
      {raw_tallies, irv_tallies, winner} = instant_runoff(votes, String.to_integer(id))
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
    if (String.trim(attrs["title"]) !== "") do
      if (attrs["choices"] === Enum.uniq(attrs["choices"])) do
        attrs = Map.update!(attrs, "choices",
                  &Enum.filter(&1, fn choice -> String.trim(choice) !== "" end))
        %Poll{}
        |> Poll.changeset(attrs)
        |> Repo.insert()
      else
        :choices_error
      end
    else
      :title_error
    end
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
