defmodule Api.Posts.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "comments" do
    field :type, :string
    field :body, :string

    belongs_to :user, Api.Accounts.User
    belongs_to :post, Api.Posts.Post
    belongs_to :parent_comment, Api.Posts.Comment
    has_many :replies, Api.Posts.Comment, foreign_key: :parent_comment_id

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
