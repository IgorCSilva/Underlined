defmodule Api.Infrastructure.Repository.Passage.Postgres.Passage do
  @moduledoc """
  Postgres-backed passage entity (Ecto schema). This is database structure,
  not a business-rule entity — it belongs to infrastructure, not the
  domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "passages" do
    field :text, :string

    belongs_to :book, Book
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(passage, attrs) do
    passage
    |> cast(attrs, [:book_id, :user_id, :text])
    |> validate_required([:book_id, :user_id, :text])
    |> validate_length(:text, min: 1, max: 1000)
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:user_id)
  end
end
