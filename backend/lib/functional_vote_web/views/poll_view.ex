defmodule FunctionalVoteWeb.PollView do
  use FunctionalVoteWeb, :view
  alias FunctionalVoteWeb.PollView

  def render("index.json", %{polls: polls}) do
    %{data: render_many(polls, PollView, "poll.json")}
  end

  def render("show.json", %{poll: poll}) do
    %{data: render_one(poll, PollView, "poll.json")}
  end

  def render("poll.json", %{poll: poll}) do
    %{id: poll.id,
      title: poll.title,
      choices: poll.choices,
      raw_tallies: poll.raw_tallies,
      tallies: poll.tallies,
      winner: poll.winner}
  end
end
