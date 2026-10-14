defmodule Api.Repo.Migrations.CreateClubReadingProgress do
  use Ecto.Migration

  def change do
    create table(:club_reading_progress, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :club_id, references(:clubs, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :chapter_id, references(:club_chapters, type: :binary_id, on_delete: :nilify_all),
        null: true

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:club_reading_progress, [:club_id, :user_id])
  end
end
