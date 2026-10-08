defmodule Api.Infrastructure.Repository.Chain.Postgres.Chain do
  @moduledoc """
  Postgres-backed idea-chain entity (Ecto schema). This is database
  structure, not a business-rule entity — it belongs to infrastructure,
  not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Chain.Postgres.ChainItem
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "idea_chains" do
    field :title, :string

    belongs_to :user, User
    has_many :chain_items, ChainItem, foreign_key: :chain_id
    field :items, {:array, :map}, virtual: true, default: []

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(chain, attrs) do
    chain
    |> cast(attrs, [:user_id, :title])
    |> validate_required([:user_id, :title])
    |> validate_length(:title, min: 1, max: 200)
    |> foreign_key_constraint(:user_id)
  end
end
