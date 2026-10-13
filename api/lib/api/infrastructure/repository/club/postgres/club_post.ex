defmodule Api.Infrastructure.Repository.Club.Postgres.ClubPost do
  @moduledoc """
  Postgres-backed club-post entity (Ecto schema): one message in a club's
  discussion, optionally tagged to one of the club's chapters. This is
  database structure, not a business-rule entity — it belongs to
  infrastructure, not the domain.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Infrastructure.Repository.Club.Postgres.{Club, ClubChapter}
  alias Api.Infrastructure.Repository.User.Postgres.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "club_posts" do
    field :body, :string
    field :comment_count, :integer, default: 0

    belongs_to :club, Club
    belongs_to :chapter, ClubChapter
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:club_id, :chapter_id, :user_id, :body])
    |> validate_required([:club_id, :user_id, :body])
    |> validate_length(:body, min: 1, max: 2000)
    |> foreign_key_constraint(:club_id)
    |> foreign_key_constraint(:chapter_id)
    |> foreign_key_constraint(:user_id)
  end
end
