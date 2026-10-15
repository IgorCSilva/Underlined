defmodule Api.Repo.Migrations.CreateUserBooks do
  use Ecto.Migration

  def change do
    create table(:user_books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:user_books, [:user_id, :book_id])
    create index(:user_books, [:book_id])
  end
end
