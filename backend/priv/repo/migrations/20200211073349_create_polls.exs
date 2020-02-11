defmodule FunctionalVote.Repo.Migrations.CreatePolls do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :title, :string
      add :choices, {:array, :string}

      timestamps()
    end

  end
end
