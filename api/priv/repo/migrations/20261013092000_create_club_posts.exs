defmodule Api.Repo.Migrations.CreateClubPosts do
  use Ecto.Migration

  def change do
    create table(:club_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :club_id, references(:clubs, type: :binary_id, on_delete: :delete_all), null: false

      add :chapter_id, references(:club_chapters, type: :binary_id, on_delete: :nilify_all),
        null: true

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :body, :text, null: false
      add :comment_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create index(:club_posts, [:club_id])
    create index(:club_posts, [:chapter_id])
    create index(:club_posts, [:inserted_at])
  end
end
