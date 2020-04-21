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
  @return {:empty_choices_error} No votes provided
  @return {:id_error} Invalid poll ID provided
  @return {:non_integer_rank_error} Vote with non-integer rank provided
  @return {:available_choices_error} Choice does not exist in poll
  @return {:duplicate_rank_error} Vote with duplicate ranks

  """
  def create_vote(attrs \\ %{}) do
    poll_id = attrs["poll_id"]
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

      # Check for existing IP
      ip_address = attrs["ip_address"]
      query = from v in "votes",
              where: v.poll_id == ^poll_id and v.ip_address == ^ip_address,
              select: v.user_id
      has_ip_address = Repo.exists?(query) || false

      # Get reCAPTCHA information
      poll = Polls.get_poll_data!(poll_id)
      use_recaptcha = poll.use_recaptcha
      recaptcha_token = attrs["recaptcha_token"]
      prevent_multiple_votes = poll.prevent_multiple_votes

      cond do
        validate_non_empty_choices(choices) == :empty_choices_error ->
          # Received empty choices list
          :empty_choices_error # RETURN ENDPOINT
        validate_integer_ranks(choices) == :non_integer_rank_error ->
          # Received a vote with a non-integer rank
          :non_integer_rank_error # RETURN ENDPOINT
        validate_duplicate_ranks(choices) == :duplicate_rank_error ->
          # Received votes with duplicate ranks
          :duplicate_rank_error # RETURN ENDPOINT
        validate_choices(choices, available_choices) == :available_choices_error ->
          # Received a choice that does not exist in this poll
          :available_choices_error # RETURN ENDPOINT
        validate_multiple_votes(prevent_multiple_votes, has_ip_address) == :multiple_votes_error ->
          # Multiple votes cannot be made for this poll
          :multiple_votes_error # RETURN ENDPOINT
        validate_recaptcha(use_recaptcha, recaptcha_token) == :recaptcha_error ->
          # reCAPTCHA verification returned an error, e.g. missing, expired, or wrong reCAPTCHA token
          :recaptcha_error # RETURN ENDPOINT
        true ->
          # No error
          IO.puts("[VoteCtx] Got #{map_size(choices)} choices")
          Enum.each choices, fn {k, v} ->
            # Maintain backwards compatibility if others want to submit ranks as ints represented as strings
            v = if is_integer(v), do: v, else: String.to_integer(v)
            choice_map = %{"poll_id"    => poll_id,
                           "user_id"    => user_id,
                           "choice"     => k,
                           "rank"       => v,
                           "ip_address" => ip_address}
            %Votes{}
            |> Votes.changeset(choice_map)
            |> Repo.insert!() # RETURN ENDPOINT
          end
      end
    else
      # Poll we are voting for does not exist
      IO.puts("[VoteCtx] poll_id #{poll_id} does not exist!")
      :id_error # RETURN ENDPOINT
    end
  end

  defp validate_non_empty_choices(choices) do
    if (choices == nil or map_size(choices) == 0) do
      IO.puts("[VoteCtx] Received an empty vote")
      IO.inspect(choices)
      :empty_choices_error
    end
  end

  defp validate_integer_ranks(choices) do
    try do
      Enum.map(choices, fn {k, v} ->
        # Maintain backwards compatibility if others want to submit ranks as ints represented as strings
        v = if is_integer(v), do: v, else: String.to_integer(v)
        {k, v}
      end)
    rescue
      ArgumentError ->
        IO.puts("[VoteCtx] Received a vote with a non-integer rank")
        IO.inspect(Map.values(choices))
        :non_integer_rank_error
    end
  end

  defp validate_duplicate_ranks(choices) do
    if Map.values(choices) !== Enum.uniq(Map.values(choices)) do
      IO.puts("[VoteCtx] Received votes with duplicate ranks:")
      IO.inspect(choices)
      :duplicate_rank_error
    end
  end

  defp validate_choices(choices, available_choices) do
    if Map.keys(choices) -- available_choices !== [] do
      IO.puts("[VoteCtx] Received a choice that does not exist in this poll:")
      IO.inspect(Map.keys(choices))
      IO.puts("[VoteCtx] Available choices:")
      IO.inspect(available_choices)
      :available_choices_error
    end
  end

  defp validate_multiple_votes(prevent_multiple_votes, has_ip_address) do
    if prevent_multiple_votes and has_ip_address do
      IO.puts("[VoteCtx] Prevented multiple votes for #{has_ip_address}")
      :multiple_votes_error
    end
  end

  defp validate_recaptcha(use_recaptcha, recaptcha_token) do
    if use_recaptcha do
      case Recaptcha.verify(recaptcha_token) do
        {:ok, _response} -> :ok
        {:error, _errors} ->
          IO.puts("[VoteCtx] Failed reCAPTCHA verification")
          :recaptcha_error
      end
    end
  end

### Template code currently not used

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
