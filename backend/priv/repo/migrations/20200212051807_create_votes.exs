defmodule FunctionalVote.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :poll_id, :integer
      add :user_id, :integer
      add :choice, :string
      add :rank, :integer

      timestamps()
    end

  end
end
