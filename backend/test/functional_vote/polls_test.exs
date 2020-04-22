defmodule FunctionalVote.PollsTest do
  use FunctionalVote.DataCase, async: true

  alias FunctionalVote.Polls

  describe "polls" do
    alias FunctionalVote.Polls.Poll

    @valid_attrs %{"choices" => ["a", "b", "c"], "title" => "test"}
    @empty_title_attrs %{"choices" => ["a", "b", "c"], "title" => ""}
    @no_title_attrs %{"choices" => ["a", "b", "c"]}
    @dup_choices_attrs %{"choices" => ["a", "b", "b"], "title" => "test"}
    @empty_choices_attrs %{"choices" => [], "title" => "test"}
    @no_choices_attrs %{"title" => "test"}
    @max_title_attrs %{"choices" => ["a", "b", "c"], "title" => "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901"}
    @max_choice_attrs %{"choices" => ["12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901", "b", "c"], "title" => "test"}
    @max_choices_attrs %{"choices" => ["a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a","a"], "title" => "test"}

    def poll_fixture(attrs \\ %{}) do
      {:ok, poll} = Polls.create_poll(attrs)
      poll
    end

    test "create_poll/1 with valid data" do
      assert {:ok, %Poll{} = poll} = Polls.create_poll(@valid_attrs)
      assert poll.choices == ["a", "b", "c"]
      assert poll.title == "test"
    end

    test "create_poll/1 with empty title returns no_title_error" do
      assert :no_title_error == Polls.create_poll(@empty_title_attrs)
    end

    test "create_poll/1 with no title returns no_title_error" do
      assert :no_title_error == Polls.create_poll(@no_title_attrs)
    end

    test "create_poll/1 with duplicate choices returns duplicate_choices_error" do
      assert :duplicate_choices_error == Polls.create_poll(@dup_choices_attrs)
    end

    test "create_poll/1 with empty choices returns no_choices_error" do
      assert :no_choices_error == Polls.create_poll(@empty_choices_attrs)
    end

    test "create_poll/1 with no choices returns no_choices_error" do
      assert :no_choices_error == Polls.create_poll(@no_choices_attrs)
    end

    test "create_poll/1 with max title returns max_title_error" do
      assert :max_title_error == Polls.create_poll(@max_title_attrs)
    end

    test "create_poll/1 with max choice returns max_choice_error" do
      assert :max_choice_error == Polls.create_poll(@max_choice_attrs)
    end

    test "create_poll/1 with max choices returns max_choices_error" do
      assert :max_choices_error == Polls.create_poll(@max_choices_attrs)
    end

    test "get_poll!/1 returns the poll with given id" do
      poll = poll_fixture(@valid_attrs)
      # A bit of odd behavior. Repo.insert() returns a poll with ip_address: nil
      # but it is saved into the DB as an empty string.
      poll = Map.put(poll, :ip_address, "")
      get_poll = Polls.get_poll!(poll.poll_id)
      assert get_poll == poll
    end

    test "poll_exists?/1 returns true when given a valid id" do
      poll = poll_fixture(@valid_attrs)
      assert Polls.poll_exists?(poll.poll_id) == true
    end

  end
end
