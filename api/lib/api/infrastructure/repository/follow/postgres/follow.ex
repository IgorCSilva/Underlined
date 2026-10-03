defmodule Api.Infrastructure.Repository.Follow.Postgres.Follow do
  @moduledoc """
  Postgres-backed follow entity (Ecto schema). This is database structure,
  not a business-rule entity — it belongs to infrastructure, not the
  domain.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import ApiWeb.Gettext

  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "follows" do
    belongs_to :follower, User
    belongs_to :followee, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :followee_id])
    |> validate_required([:follower_id, :followee_id])
    |> validate_not_self()
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:followee_id)
    |> unique_constraint([:follower_id, :followee_id])
  end

  defp validate_not_self(changeset) do
    follower_id = get_field(changeset, :follower_id)
    followee_id = get_field(changeset, :followee_id)

    if follower_id && followee_id && follower_id == followee_id do
      add_error(changeset, :followee_id, gettext("cannot follow yourself"))
    else
      changeset
    end
  end
end
