defmodule Api.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @max_keywords 8

  schema "posts" do
    field :thinking, :string
    field :keyword_names, {:array, :string}, virtual: true, default: []
    field :like_count, :integer, default: 0
    field :liked_by_user, :boolean, virtual: true, default: false

    belongs_to :user, Api.Accounts.User
    belongs_to :book, Api.Catalog.Book
    belongs_to :passage, Api.Posts.Passage
    many_to_many :keywords, Api.Posts.Keyword, join_through: "post_keywords", on_replace: :delete

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:user_id, :book_id, :passage_id, :thinking, :keyword_names])
    |> validate_required([:user_id, :book_id, :passage_id, :thinking])
    |> validate_length(:thinking, min: 1, max: 2000)
    |> validate_length(:keyword_names,
      max: @max_keywords,
      message: "up to #{@max_keywords} keywords allowed"
    )
    |> validate_keyword_names()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:passage_id)
    |> unique_constraint(:passage_id)
  end

  defp validate_keyword_names(changeset) do
    validate_change(changeset, :keyword_names, fn :keyword_names, names ->
      if Enum.all?(names, &(String.length(&1) in 1..40)) do
        []
      else
        [keyword_names: "each keyword must be 1-40 characters"]
      end
    end)
  end
end
