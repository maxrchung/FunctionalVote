defmodule FunctionalVote.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset

  schema "polls" do
    field :choices, {:array, :string}
    field :title, :string
    field :winner, :string
    field :poll_id, :string
    field :use_recaptcha, :bool

    timestamps()
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:title, :choices, :poll_id, :use_recaptcha])
    |> validate_required([:title, :choices, :poll_id, :use_recaptcha])
  end
end
