defmodule FunctionalVote.Polls.Results do
  use Ecto.Schema
  import Ecto.Changeset

  schema "results" do
    field :choice, :string
    field :poll_id, :string
    field :round, :integer
    field :votes, :integer

    timestamps()
  end

  @doc false
  def changeset(results, attrs) do
    results
    |> cast(attrs, [:poll_id, :round, :choice, :votes])
    |> validate_required([:poll_id, :round, :choice, :votes])
  end
end
