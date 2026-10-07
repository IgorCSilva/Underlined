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
    # DB column is :text (unbounded) as of the widen_passages_text migration
    # — the 300-char business limit lives only here, in validate_length.

    belongs_to :book, Book
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(passage, attrs) do
    passage
    |> cast(attrs, [:book_id, :user_id, :text])
    |> validate_required([:book_id, :user_id, :text])
    |> validate_length(:text, min: 1, max: 300)
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc "Editing a passage may only ever change its text — not its book, author, or owning post."
  def update_changeset(passage, attrs) do
    passage
    |> cast(attrs, [:text])
    |> validate_required([:text])
    |> validate_length(:text, min: 1, max: 300)
  end
end
