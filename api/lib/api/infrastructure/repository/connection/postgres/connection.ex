defmodule Api.Infrastructure.Repository.Connection.Postgres.Connection do
  @moduledoc """
  Postgres-backed post-connection entity (Ecto schema). This is database
  structure, not a business-rule entity — it belongs to infrastructure, not
  the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Infrastructure.Repository.User.Postgres.User

  @relationship_types ~w(similar_idea opposite_idea expands_on contradicts example_of personal_connection)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "post_connections" do
    field :relationship_type, :string

    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :related_post, Post

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:user_id, :post_id, :related_post_id, :relationship_type])
    |> validate_required([:user_id, :post_id, :related_post_id, :relationship_type])
    |> validate_inclusion(:relationship_type, @relationship_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:related_post_id)
    |> unique_constraint([:post_id, :related_post_id, :relationship_type])
  end
end
