defmodule Api.Infrastructure.Repository.Comment.Postgres.Comment do
  @moduledoc """
  Postgres-backed comment entity (Ecto schema). This is database structure,
  not a business-rule entity — it belongs to infrastructure, not the
  domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "comments" do
    field :type, :string
    field :body, :string

    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :parent_comment, __MODULE__
    has_many :replies, __MODULE__, foreign_key: :parent_comment_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:user_id, :post_id, :parent_comment_id, :type, :body])
    |> validate_required([:user_id, :post_id, :type, :body])
    |> validate_inclusion(:type, ["comment", "reply"])
    |> validate_length(:body, min: 1, max: 1000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:parent_comment_id)
  end
end
