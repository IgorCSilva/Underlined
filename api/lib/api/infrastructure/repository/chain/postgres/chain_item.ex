defmodule Api.Infrastructure.Repository.Chain.Postgres.ChainItem do
  @moduledoc """
  Postgres-backed idea-chain-item entity (Ecto schema): one step of a
  chain, linked to its predecessor so the chain's order can be walked with
  a recursive CTE instead of relying on a renumbered position column. This
  is database structure, not a business-rule entity — it belongs to
  infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Chain.Postgres.Chain
  alias Api.Infrastructure.Repository.Post.Postgres.Post

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "idea_chain_items" do
    belongs_to :chain, Chain
    belongs_to :post, Post
    belongs_to :previous_item, __MODULE__, foreign_key: :previous_item_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(chain_item, attrs) do
    chain_item
    |> cast(attrs, [:chain_id, :post_id, :previous_item_id])
    |> validate_required([:chain_id, :post_id])
    |> foreign_key_constraint(:chain_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:previous_item_id)
    |> unique_constraint(:previous_item_id)
  end
end
