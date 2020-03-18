defmodule FunctionalVote.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset

  schema "polls" do
    field :choices, {:array, :string}
    field :title, :string
    field :winner, :string
    field :poll_id, :string

    timestamps()
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:title, :choices, :poll_id])
    |> validate_required([:title, :choices, :poll_id])
  end
end
