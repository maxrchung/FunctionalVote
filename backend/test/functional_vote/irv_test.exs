defmodule FunctionalVote.IrvTest do
  use FunctionalVote.DataCase

  alias FunctionalVote.Votes
  alias FunctionalVote.Polls

  setup do
    attrs = %{"choices" => ["a", "b", "c", "d"], "title" => "test"}
    {:ok, poll} = Polls.create_poll(attrs)

    %{poll_id: poll.poll_id,
      choices: poll.choices,
      title:   poll.title,
      winner:  poll.winner}
  end

  describe "deterministic instant runoff voting" do

    test "simple majority", context do
      # 1 vote for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that a is the winner
      {_, winner} = Votes.get_votes(context.poll_id)
                    |> Polls.instant_runoff(context.poll_id, true)
      assert "a" = winner
      # 2 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that b is the winner
      {_, winner} = Votes.get_votes(context.poll_id)
                    |> Polls.instant_runoff(context.poll_id, true)
      assert "b" = winner
      # 4 votes for c
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that c is the winner
      {_, winner} = Votes.get_votes(context.poll_id)
                    |> Polls.instant_runoff(context.poll_id, true)
      assert "c" = winner
    end

    test "1 round elim no runoff into simple majority", context do
      # 1 vote for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # 2 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # 3 votes for c
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that c is the winner and rounds are correct
      {irv_tallies, winner} = Votes.get_votes(context.poll_id)
                              |> Polls.instant_runoff(context.poll_id, true)
      assert "c" = winner
      assert [%{"a" => 1, "b" => 2, "c" => 3, "d" => 0},
              %{"a" => 1, "b" => 2, "c" => 3},
              %{"b" => 2, "c" => 3}] = irv_tallies
    end

    test "1 round elim runoff flip majority", context do
      # 2 votes for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # 3 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # 4 votes for c
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that c is the winner and rounds are correct
      {irv_tallies, winner} = Votes.get_votes(context.poll_id)
                              |> Polls.instant_runoff(context.poll_id, true)
      assert "b" = winner
      assert [%{"a" => 2, "b" => 3, "c" => 4, "d" => 0},
              %{"a" => 2, "b" => 3, "c" => 4},
              %{"b" => 5, "c" => 4}] = irv_tallies
    end

    test "1 round elim split runoff", context do
      # 2 votes for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "c" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # 3 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # 4 votes for c
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that c is the winner and rounds are correct
      {irv_tallies, winner} = Votes.get_votes(context.poll_id)
                              |> Polls.instant_runoff(context.poll_id, true)
      assert "c" = winner
      assert [%{"a" => 2, "b" => 3, "c" => 4, "d" => 0},
              %{"a" => 2, "b" => 3, "c" => 4},
              %{"b" => 4, "c" => 5}] = irv_tallies
    end

  end
end
