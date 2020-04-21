defmodule FunctionalVote.Repo.Migrations.AddVoteIpAddress do
  use Ecto.Migration

  def change do
    alter table(:votes) do
      add :ip_address, :text, default: ""
    end
  end
end
