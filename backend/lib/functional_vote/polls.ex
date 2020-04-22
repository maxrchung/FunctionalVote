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
            where: p.poll_id == ^poll_id,
            select: p.winner
    _winner = Repo.one(query)
  end

  @doc """
  Save the tallies to the database
  @param poll_id
  @param talles_by_count
  """
  def write_round(poll_id, tallies_by_choice, round) do
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
                        |> Enum.map(fn {_k, v} -> Map.new(v) end)
  end

  @doc """
  Instant-runoff voting (IRV) algorithm

  2 base cases marked with # BASE CASE ENDPOINT
  Recursion endpoint marked with # RETURN ENDPOINT

  @param votes - votes data from DB
  @param poll_id - poll_id
  @return {tallies_by_choice, winner}
  """
  def instant_runoff_recurse(votes, poll_id, round, eliminated \\ []) do
    available_choices = get_poll_choices(poll_id)
    tallies_by_choice = Map.values(votes)
                        |> Enum.filter(fn elem -> elem !== [] end) # Remove ballots that are now empty
                        |> List.zip() # nth choice of each ballot
                        |> List.first() # 1st choice of each ballot
                        |> Tuple.to_list()
                        |> Enum.frequencies() # tally them up
    zero_tally_choices = available_choices -- Map.keys(tallies_by_choice) # Choices with zero tallies
                         |> Enum.filter(fn choice -> choice not in eliminated end) # that are not eliminated
                         |> Enum.into(%{}, fn choice -> {choice, 0} end) # Add it to the map
    tallies_by_choice = Map.merge(tallies_by_choice, zero_tally_choices)
    IO.puts("[PollCtx] Votes going into round #{round}:")
    IO.inspect(tallies_by_choice)
    if (round == 0) do
      # Clear previous results for this poll_id as we are rerunning the algorithm
      clear_rounds(poll_id)
    end
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
        round = round + 1 # Round 1 = Tallies after first elimination
        loser = tallies_by_count[Map.keys(tallies_by_count) |> Enum.min()] |> Enum.random()
        eliminated = eliminated ++ [loser]
        IO.puts("[PollCtx] Eliminated #{loser} in round #{round}")
        # Remove all votes cast for this choice
        votes = for {k, v} <- votes,
                into: %{},
                do: {k,
                    Enum.filter(v, fn choice -> choice !== loser end)
                }
        {tallies_by_choice, winner} = instant_runoff_recurse(votes, poll_id, round, eliminated)
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
  @return {irv_tallies, winner} - tallies for each round, final winner
  """
  def instant_runoff(votes, poll_id, write_winner \\ false) do
    unless (write_winner) do
      # Just read the winner and return raw_tallies and winner
      winner = read_winner(poll_id)
      if winner == nil do
        winner = get_poll_choices(poll_id) |> Enum.random()
        IO.puts("[PollCtx] New poll, randomized winner to be #{winner}")
        write_winner(poll_id, winner)
        irv_tallies = []
        {irv_tallies, winner} # RETURN ENDPOINT
      else
        irv_tallies = read_rounds(poll_id)
        {irv_tallies, winner} # RETURN ENDPOINT
      end
    else
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
        {_, winner} = instant_runoff_recurse(votes, poll_id, 0)
        irv_tallies = read_rounds(poll_id)
        {irv_tallies, winner} # RETURN ENDPOINT
    end
  end

  @doc """
  @param id
  @return true if the poll exists
  """
  def poll_exists?(poll_id) do
    query = from p in Poll,
              where: p.poll_id == ^poll_id
    Repo.exists?(query)
  end

  @doc """
  @param id, choice
  @return choices of the given poll id
  """
  def get_poll_choices(poll_id) do
    query = from p in Poll,
              where: p.poll_id == ^poll_id,
              select: p.choices
    Repo.one(query)
  end

  @doc """
  Gets a single poll.
  Raises `Ecto.NoResultsError` if the Poll does not exist.
  """
  def get_poll!(poll_id), do: Repo.get_by!(Poll, poll_id: poll_id)

  @doc """
  Gets poll data for use in IRV.

  Raises `Ecto.NoResultsError` if the Poll does not exist.
  """
  def get_poll_data!(poll_id) do
    IO.puts("[PollCtx] Get poll data")
    poll = Repo.get_by!(Poll, poll_id: poll_id)
    votes = Votes.get_votes(poll_id)
    {irv_tallies, winner} = instant_runoff(votes, poll_id)
    calculated = %{tallies: irv_tallies, winner: winner}
    Map.merge(poll, calculated)
  end

  @doc """
  Creates a poll.

  ## Examples

      iex> create_poll(%{field: value})
      {:ok, %Poll{}}

      iex> create_poll(%{field: bad_value})
      :no_title_error
      :max_title_error
      :no_choices_error
      :max_choices_error
      :duplicate_choices_error
      :submission_timeout_error

  """
  def create_poll(attrs \\ %{}) do
    IO.puts("[PollCtx] Create poll")

    cond do
      attrs["title"] === nil or String.trim(attrs["title"]) === "" ->
        :no_title_error # RETURN ENDPOINT

      String.length(attrs["title"]) > 100 ->
        :max_title_error # RETURN ENDPOINT

      attrs["choices"] === nil ->
        :no_choices_error # RETURN ENDPOINT

      true ->
        attrs = Map.update!(attrs, "choices", &Enum.filter(&1, fn choice -> String.trim(choice) !== "" end))
        cond do
          length(attrs["choices"]) === 0 ->
            :no_choices_error # RETURN ENDPOINT

          length(attrs["choices"]) > 100 ->
            :max_choices_error # RETURN ENDPOINT

          attrs["choices"] !== Enum.uniq(attrs["choices"]) ->
            :duplicate_choices_error # RETURN ENDPOINT

          Enum.find(attrs["choices"], fn x -> String.length(x) > 100 end) !== nil ->
            :max_choice_error # RETURN ENDPOINT

          true ->
            poll_id = StringGenerator.poll_id_of_length(8)
            IO.inspect(poll_id)
            attrs = Map.put_new(attrs, "poll_id", poll_id)

            # Add empty ip if it is missing
            attrs = if Map.has_key?(attrs, "ip_address"), do: attrs, else: Map.put(attrs, "ip_address", "")
            ip_address = attrs["ip_address"]

            # Limit poll creations
            query = from p in Poll,
              where: p.ip_address == ^ip_address,
              order_by: [desc: p.inserted_at],
              select: p.inserted_at
            # Default to Unix epoch if inserted_at cannot be found
            last_inserted = query |> first |> Repo.one || ~N[1970-01-01 00:00:00]
            submission_timeout = Application.get_env(:functional_vote, FunctionalVoteWeb.Endpoint)[:submission_timeout]

            if NaiveDateTime.diff(NaiveDateTime.utc_now(), last_inserted, :millisecond) < submission_timeout do
              :submission_timeout_error
            else
              # Add default options if they are missing
              attrs = if Map.has_key?(attrs, "prevent_multiple_votes"), do: attrs, else: Map.put(attrs, "prevent_multiple_votes", false)
              attrs = if Map.has_key?(attrs, "use_recaptcha"), do: attrs, else: Map.put(attrs, "use_recaptcha", false)

              %Poll{}
                |> Poll.changeset(attrs)
                |> Repo.insert() # RETURN ENDPOINT
            end
        end
    end
  end

### Template code currently not used

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

# https://stackoverflow.com/a/38315317
defmodule StringGenerator do
  alias FunctionalVote.Polls
  @chars "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.split("")

  def string_of_length(length) do
    Enum.reduce((1..length), [], fn (_i, acc) ->
      [Enum.random(@chars) | acc]
    end) |> Enum.join("")
  end

  def poll_id_of_length(length) do
    poll_id = string_of_length(length)
    if (Polls.poll_exists?(poll_id)) do
      _poll_id = poll_id_of_length(length)
    else
      poll_id
    end
  end
end
