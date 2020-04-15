defmodule FunctionalVote.Repo.Migrations.AddUseRecaptcha do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :use_recaptcha, :boolean, default: false
    end
  end
end
