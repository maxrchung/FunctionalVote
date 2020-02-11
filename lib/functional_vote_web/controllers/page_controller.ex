defmodule FunctionalVoteWeb.PageController do
  use FunctionalVoteWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, %{"title" => title, "choices" => choices} = _params) do
    IO.puts("[Controller] Creating new poll \"#{title}\" with #{length(choices)} choices")
    render(conn, "index.html")
  end

end
