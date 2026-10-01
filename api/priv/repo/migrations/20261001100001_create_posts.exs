defmodule Api.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false

      add :passage_id, references(:passages, type: :binary_id, on_delete: :delete_all),
        null: false

      add :thinking, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:posts, [:user_id])
    create index(:posts, [:book_id])
    create unique_index(:posts, [:passage_id])
    create index(:posts, [:inserted_at])
  end
end
