defmodule FunctionalVote.Repo.Migrations.AddPollIpAddress do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :ip_address, :text, default: ""
    end
  end
end
