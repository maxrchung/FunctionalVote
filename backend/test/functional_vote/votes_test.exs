defmodule FunctionalVote.VotesTest do
  use FunctionalVote.DataCase

  alias FunctionalVote.Votes
  alias FunctionalVote.Polls

  setup do
    attrs = %{"choices" => ["a", "b", "c"], "title" => "test"}
    {:ok, poll} = Polls.create_poll(attrs)

    %{poll_id: poll.poll_id,
      choices: poll.choices,
      title:   poll.title,
      winner:  poll.winner}
  end

  describe "votes" do

    test "create_vote/1 with valid data", context do
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 2, "c" => 3}}
      assert :ok = Votes.create_vote(attrs)
      assert %{0 => ["a", "b", "c"]} = Votes.get_votes(context.poll_id)

      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 2, "b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      assert %{0 => ["a", "b", "c"], 1 => ["b", "a"]} = Votes.get_votes(context.poll_id)

      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 0, "b" => 4}}
      assert :ok = Votes.create_vote(attrs)
      assert %{0 => ["a", "b", "c"], 1 => ["b", "a"]} = Votes.get_votes(context.poll_id)
    end

    test "create_vote/1 with no choices returns :empty_choices_error", context do
      attrs = %{"poll_id" => context.poll_id}
      assert :empty_choices_error = Votes.create_vote(attrs)
      assert %{} = Votes.get_votes(context.poll_id)
    end

    test "create_vote/1 with invalid poll id returns :id_error", context do
      attrs = %{"poll_id" => "無效", "choices" => %{"a" => 1, "b" => 2, "c" => 3}}
      assert :id_error = Votes.create_vote(attrs)
      assert %{} = Votes.get_votes(context.poll_id)
    end

    test "create_vote/1 with non-integer rank returns :non_integer_rank_error", context do
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => "x", "b" => "y", "c" => 1}}
      assert :non_integer_rank_error = Votes.create_vote(attrs)
      assert %{} = Votes.get_votes(context.poll_id)
    end

    test "create_vote/1 with an invalid choice returns :available_choices_error", context do
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "z" => 2}}
      assert :available_choices_error = Votes.create_vote(attrs)
      assert %{} = Votes.get_votes(context.poll_id)
    end

    test "create_vote/1 with duplicate ranks returns :duplicate_rank_error", context do
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 1}}
      assert :duplicate_rank_error = Votes.create_vote(attrs)
      assert %{} = Votes.get_votes(context.poll_id)
    end

  end
end
