defmodule Api.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false

      add :passage_id, references(:passages, type: :binary_id, on_delete: :delete_all),
        null: false

      add :body, :string, null: false
      add :answer_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create index(:questions, [:book_id])
    create unique_index(:questions, [:passage_id])
    create index(:questions, [:inserted_at])
  end
end
