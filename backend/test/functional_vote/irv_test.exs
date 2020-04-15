defmodule FunctionalVote.IrvTest do
  use FunctionalVote.DataCase

  alias FunctionalVote.Votes
  alias FunctionalVote.Polls

  setup do
    attrs = %{"choices" => ["a", "b", "c", "d"], "title" => "test", "use_recaptcha" => false}
    {:ok, poll} = Polls.create_poll(attrs)

    %{poll_id: poll.poll_id,
      choices: poll.choices,
      title:   poll.title,
      winner:  poll.winner}
  end

  describe "deterministic instant runoff voting" do

    @tag irv: "1"
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

    @tag irv: "2"
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

    @tag irv: "3"
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

    @tag irv: "4"
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

    @tag irv: "5"
    test "2 round elim runoff into majority", context do
      # 2 votes for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 2, "d" => 3}}
      assert :ok = Votes.create_vote(attrs)
      # 2 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # 1 vote for c
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1, "a" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # 3 votes for d
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that d is the winner and rounds are correct
      {irv_tallies, winner} = Votes.get_votes(context.poll_id)
                              |> Polls.instant_runoff(context.poll_id, true)
      assert "d" = winner
      assert [%{"a" => 2, "b" => 2, "c" => 1, "d" => 3},
              %{"a" => 3, "b" => 2, "d" => 3},
              %{"a" => 3, "d" => 5}] = irv_tallies
    end

    @tag irv: "6"
    test "2 round elim split into tie", context do
      # 2 votes for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 2, "d" => 3}}
      assert :ok = Votes.create_vote(attrs)
      # 2 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "c" => 2, "a" => 3}}
      assert :ok = Votes.create_vote(attrs)
      # 1 vote for c
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"c" => 1, "a" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # 3 votes for d
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that d or a is the winner and rounds are correct
      {irv_tallies, winner} = Votes.get_votes(context.poll_id)
                              |> Polls.instant_runoff(context.poll_id, true)
      assert winner == "d" or winner == "a"
      assert [%{"a" => 2, "b" => 2, "c" => 1, "d" => 3},
              %{"a" => 3, "b" => 2, "d" => 3},
              %{"a" => 4, "d" => 4}] = irv_tallies
    end

    @tag irv: "7"
    test "2 round tiebreak elim same result either way", context do
      # 2 votes for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "c" => 2, "d" => 3}}
      assert :ok = Votes.create_vote(attrs)
      # 2 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "c" => 2, "d" => 3}}
      assert :ok = Votes.create_vote(attrs)
      # 3 votes for d
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1}}
      assert :ok = Votes.create_vote(attrs)
      # Check that d is the winner and rounds are correct
      {irv_tallies, winner} = Votes.get_votes(context.poll_id)
                              |> Polls.instant_runoff(context.poll_id, true)
      assert "d" = winner
      assert irv_tallies == [%{"a" => 2, "b" => 2, "c" => 0, "d" => 3},
                %{"a" => 2, "b" => 2, "d" => 3},
                %{"b" => 2, "d" => 5}] or
             irv_tallies == [%{"a" => 2, "b" => 2, "c" => 0, "d" => 3},
                %{"a" => 2, "b" => 2, "d" => 3},
                %{"a" => 2, "d" => 5}]
    end

    @tag irv: "8"
    test "2 round tiebreak elim into tie", context do
      # 2 votes for a
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"a" => 1, "b" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # 2 votes for b
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "d" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"b" => 1, "a" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # 2 votes for d
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1, "a" => 2}}
      assert :ok = Votes.create_vote(attrs)
      attrs = %{"poll_id" => context.poll_id, "choices" => %{"d" => 1, "b" => 2}}
      assert :ok = Votes.create_vote(attrs)
      # Check that 3 possible winners, 3 possible solutions
      {irv_tallies, winner} = Votes.get_votes(context.poll_id)
                              |> Polls.instant_runoff(context.poll_id, true)
      assert winner !== "c"
      assert irv_tallies ==
        [%{"a" => 2, "b" => 2, "c" => 0, "d" => 2}, # a eliminated, tie between b and d
         %{"a" => 2, "b" => 2, "d" => 2},
         %{"b" => 3, "d" => 3}]
        or irv_tallies ==
        [%{"a" => 2, "b" => 2, "c" => 0, "d" => 2}, # b eliminated, tie between a and d
         %{"a" => 2, "b" => 2, "d" => 2},
         %{"a" => 3, "d" => 3}]
        or irv_tallies ==
        [%{"a" => 2, "b" => 2, "c" => 0, "d" => 2}, # d eliminated, tie between a and b
         %{"a" => 2, "b" => 2, "d" => 2},
         %{"a" => 3, "b" => 3}]
    end

  end
end
