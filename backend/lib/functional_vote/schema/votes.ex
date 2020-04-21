defmodule FunctionalVote.Polls.Votes do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votes" do
    field :choice, :string
    field :poll_id, :string
    field :rank, :integer
    field :user_id, :integer
    field :ip_address, :string

    timestamps()
  end

  @doc false
  def changeset(votes, attrs) do
    votes
    |> cast(attrs, [:poll_id, :user_id, :choice, :rank, :ip_address])
    |> validate_required([:poll_id, :user_id, :choice, :rank])
  end
end
