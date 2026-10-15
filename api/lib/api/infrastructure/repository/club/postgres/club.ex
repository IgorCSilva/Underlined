defmodule Api.Infrastructure.Repository.Club.Postgres.Club do
  @moduledoc """
  Postgres-backed book-club entity (Ecto schema). This is database
  structure, not a business-rule entity — it belongs to infrastructure,
  not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.Club.Postgres.ClubMembership
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "clubs" do
    field :name, :string
    field :description, :string
    field :member_count, :integer, virtual: true, default: 0
    field :members_preview, {:array, :map}, virtual: true, default: []
    field :joined_by_user, :boolean, virtual: true, default: false

    belongs_to :book, Book
    belongs_to :creator, User
    has_many :memberships, ClubMembership

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(club, attrs) do
    club
    |> cast(attrs, [:name, :description, :book_id, :creator_id])
    |> validate_required([:name, :book_id, :creator_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
    |> foreign_key_constraint(:book_id)
    |> foreign_key_constraint(:creator_id)
  end
end
