defmodule Api.Infrastructure.Repository.Club.Postgres.ClubReadingProgress do
  @moduledoc """
  Postgres-backed entity for one reader's progress through a club's
  reading schedule: the furthest chapter they've read, used to decide
  whether later-chapter discussion should be spoiler-blocked for them.
  This is database structure, not a business-rule entity — it belongs to
  infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Club.Postgres.{Club, ClubChapter}
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "club_reading_progress" do
    belongs_to :club, Club
    belongs_to :user, User
    belongs_to :chapter, ClubChapter

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(progress, attrs) do
    progress
    |> cast(attrs, [:club_id, :user_id, :chapter_id])
    |> validate_required([:club_id, :user_id])
    |> foreign_key_constraint(:club_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:chapter_id)
    |> unique_constraint([:club_id, :user_id])
  end
end
