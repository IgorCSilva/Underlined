defmodule Api.Infrastructure.Repository.Keyword.Postgres.Keyword do
  @moduledoc """
  Postgres-backed keyword entity (Ecto schema). This is database structure,
  not a business-rule entity — it belongs to infrastructure, not the
  domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Post.Postgres.Post

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "keywords" do
    field :name, :string

    many_to_many :posts, Post, join_through: "post_keywords"

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(keyword, attrs) do
    keyword
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 40)
    |> unique_constraint(:name)
  end
end
