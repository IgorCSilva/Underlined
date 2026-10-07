defmodule Api.Infrastructure.Repository.Post.Postgres.Post do
  @moduledoc """
  Postgres-backed post entity (Ecto schema). This is database structure,
  not a business-rule entity — it belongs to infrastructure, not the
  domain.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import ApiWeb.Gettext

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.Keyword.Postgres.Keyword
  alias Api.Infrastructure.Repository.Passage.Postgres.Passage
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @max_keywords 8

  schema "posts" do
    field :thinking, :string
    field :keyword_names, {:array, :string}, virtual: true, default: []
    field :like_count, :integer, default: 0
    field :liked_by_user, :boolean, virtual: true, default: false
    field :bookmarked_by_user, :boolean, virtual: true, default: false
    field :comment_count, :integer, default: 0
    field :spoiler, :boolean, default: false

    belongs_to :user, User
    belongs_to :book, Book
    belongs_to :passage, Passage
    many_to_many :keywords, Keyword, join_through: "post_keywords", on_replace: :delete

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:user_id, :book_id, :passage_id, :thinking, :keyword_names, :spoiler])
    |> validate_required([:user_id, :book_id, :passage_id, :thinking])
    |> validate_length(:thinking, min: 1, max: 2000)
    |> validate_length(:keyword_names,
      max: @max_keywords,
      message: gettext("up to %{max} keywords allowed", max: @max_keywords)
    )
    |> validate_keyword_names()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:passage_id)
    |> unique_constraint(:passage_id)
  end

  @doc "Editing a post may only ever change its thinking, spoiler flag — not its author, book, passage, or keywords."
  def update_changeset(post, attrs) do
    post
    |> cast(attrs, [:thinking, :spoiler])
    |> validate_required([:thinking])
    |> validate_length(:thinking, min: 1, max: 2000)
  end

  defp validate_keyword_names(changeset) do
    validate_change(changeset, :keyword_names, fn :keyword_names, names ->
      if Enum.all?(names, &(String.length(&1) in 1..40)) do
        []
      else
        [keyword_names: gettext("each keyword must be 1-40 characters")]
      end
    end)
  end
end
