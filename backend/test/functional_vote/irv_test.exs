defmodule FunctionalVote.IrvTest do
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

  describe "instant runoff voting" do

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

  end
end
