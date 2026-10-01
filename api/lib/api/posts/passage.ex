defmodule Api.Posts.Passage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "passages" do
    field :text, :string

    belongs_to :book, Api.Catalog.Book
    belongs_to :user, Api.Accounts.User

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
