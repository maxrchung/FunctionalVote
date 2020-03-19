defmodule FunctionalVote.Repo.Migrations.CreateResults do
  use Ecto.Migration

  def change do
    create table(:results) do
      add :poll_id, :text
      add :round, :integer
      add :choice, :text
      add :votes, :integer

      timestamps()
    end

  end
end
