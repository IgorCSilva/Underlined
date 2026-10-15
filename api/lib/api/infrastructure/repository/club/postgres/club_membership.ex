defmodule Api.Infrastructure.Repository.Club.Postgres.ClubMembership do
  @moduledoc """
  Postgres-backed club-membership entity (Ecto schema): join row between a
  club and one of its members.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Club.Postgres.Club
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "club_memberships" do
    belongs_to :club, Club
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:club_id, :user_id])
    |> validate_required([:club_id, :user_id])
    |> foreign_key_constraint(:club_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:club_id, :user_id])
  end
end
