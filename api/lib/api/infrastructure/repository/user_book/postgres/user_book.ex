defmodule Api.Infrastructure.Repository.UserBook.Postgres.UserBook do
  @moduledoc """
  Postgres-backed entity for one user's shelving of one book onto their
  bookcase. This is database structure, not a business-rule entity — it
  belongs to infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.User.Postgres.User

  @statuses ~w(to_read reading read)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_books" do
    field :status, :string

    belongs_to :user, User
    belongs_to :book, Book

    timestamps(type: :utc_datetime_usec)
  end

  def statuses, do: @statuses

  def changeset(user_book, attrs) do
    user_book
    |> cast(attrs, [:user_id, :book_id, :status])
    |> validate_required([:user_id, :book_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:book_id)
    |> unique_constraint([:user_id, :book_id])
  end
end
