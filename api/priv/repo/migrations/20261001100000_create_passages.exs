defmodule Api.Repo.Migrations.CreatePassages do
  use Ecto.Migration

  def change do
    create table(:passages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :text, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:passages, [:book_id])
    create index(:passages, [:user_id])
  end
end
