defmodule Api.Infrastructure.Repository.Club.Postgres.ClubChapter do
  @moduledoc """
  Postgres-backed club-chapter entity (Ecto schema): one segment of a
  club's reading schedule. This is database structure, not a business-rule
  entity — it belongs to infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Club.Postgres.Club

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "club_chapters" do
    field :position, :integer
    field :label, :string
    field :current, :boolean, virtual: true, default: false

    belongs_to :club, Club

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(chapter, attrs) do
    chapter
    |> cast(attrs, [:club_id, :position, :label])
    |> validate_required([:club_id, :position, :label])
    |> validate_length(:label, min: 1, max: 100)
    |> foreign_key_constraint(:club_id)
    |> unique_constraint([:club_id, :position])
  end
end
