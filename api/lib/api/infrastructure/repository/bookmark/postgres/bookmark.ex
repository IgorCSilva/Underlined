defmodule Api.Infrastructure.Repository.Bookmark.Postgres.Bookmark do
  @moduledoc """
  Postgres-backed bookmark entity (Ecto schema). This is database
  structure, not a business-rule entity — it belongs to infrastructure,
  not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bookmarks" do
    belongs_to :user, User
    belongs_to :post, Post

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(bookmark, attrs) do
    bookmark
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> unique_constraint([:user_id, :post_id])
  end
end
