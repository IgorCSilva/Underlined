defmodule Api.Infrastructure.Repository.InterestProfile.Postgres.InterestProfile do
  @moduledoc """
  Postgres-backed cache of one (user, keyword) pair's post count — the
  aggregate behind Step 12's interest bars and similar-readers overlap
  query. This is database structure, not a business-rule entity; it
  belongs to infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interest_profiles" do
    field :user_id, :binary_id
    field :keyword_id, :binary_id
    field :post_count, :integer, default: 0

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:user_id, :keyword_id, :post_count])
    |> validate_required([:user_id, :keyword_id, :post_count])
    |> unique_constraint([:user_id, :keyword_id])
  end
end
