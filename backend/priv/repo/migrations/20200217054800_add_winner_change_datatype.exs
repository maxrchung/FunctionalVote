defmodule FunctionalVote.Repo.Migrations.AddWinnerChangeDatatype do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :winner, :text, null: true
      modify :title, :text
      modify :choices, {:array, :text}

    end

    alter table(:votes) do
      modify :choice, :text

    end

  end
end
