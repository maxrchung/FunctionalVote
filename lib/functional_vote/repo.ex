defmodule FunctionalVote.Repo do
  use Ecto.Repo,
    otp_app: :functional_vote,
    adapter: Ecto.Adapters.Postgres
end
