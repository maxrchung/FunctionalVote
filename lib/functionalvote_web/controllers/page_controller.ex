defmodule FunctionalvoteWeb.PageController do
  use FunctionalvoteWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
