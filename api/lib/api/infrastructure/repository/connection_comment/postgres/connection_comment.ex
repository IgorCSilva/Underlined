defmodule Api.Infrastructure.Repository.ConnectionComment.Postgres.ConnectionComment do
  @moduledoc """
  Postgres-backed entity (Ecto schema) for a comment on a connection's
  debate thread. This is database structure, not a business-rule entity —
  it belongs to infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Connection.Postgres.Connection
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "connection_comments" do
    field :type, :string
    field :body, :string
    field :side, :string, default: "neutral"

    belongs_to :user, User
    belongs_to :connection, Connection
    belongs_to :parent_comment, __MODULE__
    has_many :replies, __MODULE__, foreign_key: :parent_comment_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:user_id, :connection_id, :parent_comment_id, :type, :body, :side])
    |> validate_required([:user_id, :connection_id, :type, :body])
    |> validate_inclusion(:type, ["comment", "reply"])
    |> validate_inclusion(:side, ["post_a", "post_b", "neutral"])
    |> validate_length(:body, min: 1, max: 1000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:connection_id)
    |> foreign_key_constraint(:parent_comment_id)
  end

  @doc "Editing a comment may only ever change its body — not its author, connection, or place in the thread."
  def update_changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body])
    |> validate_required([:body])
    |> validate_length(:body, min: 1, max: 1000)
  end
end
