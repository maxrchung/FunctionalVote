defmodule FunctionalVote.Repo.Migrations.PollIdString do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :poll_id, :text

    end
  end
end
