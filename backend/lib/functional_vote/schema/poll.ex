defmodule FunctionalVote.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset

  schema "polls" do
    field :choices, {:array, :string}
    field :title, :string
    field :winner, :string
    field :poll_id, :string
    field :use_recaptcha, :boolean
    field :prevent_multiple_votes, :boolean
    field :ip_address, :string

    timestamps()
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:title, :choices, :poll_id, :use_recaptcha, :prevent_multiple_votes, :ip_address])
    # ip_address is not required so it can accept an empty string representing an unknown IP address
    |> validate_required([:title, :choices, :poll_id, :use_recaptcha, :prevent_multiple_votes])
  end
end
