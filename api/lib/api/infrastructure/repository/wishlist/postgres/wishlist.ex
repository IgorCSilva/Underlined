defmodule Api.Infrastructure.Repository.Wishlist.Postgres.Wishlist do
  @moduledoc """
  Postgres-backed entity for one user wanting one book. This is database
  structure, not a business-rule entity — it belongs to infrastructure,
  not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "book_wishlist" do
    belongs_to :user, User
    belongs_to :book, Book

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(wishlist_item, attrs) do
    wishlist_item
    |> cast(attrs, [:user_id, :book_id])
    |> validate_required([:user_id, :book_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:book_id)
    |> unique_constraint([:user_id, :book_id])
  end
end
