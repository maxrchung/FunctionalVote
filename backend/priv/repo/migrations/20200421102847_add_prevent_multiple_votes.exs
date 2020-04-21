defmodule FunctionalVote.Repo.Migrations.AddPreventMultipleVotes do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :prevent_multiple_votes, :boolean, default: false
    end
  end
end
