defmodule Functionalvote.Repo do
  use Ecto.Repo,
    otp_app: :functionalvote,
    adapter: Ecto.Adapters.Postgres
end
