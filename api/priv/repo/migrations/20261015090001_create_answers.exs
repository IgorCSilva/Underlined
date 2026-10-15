defmodule Api.Repo.Migrations.CreateAnswers do
  use Ecto.Migration

  def change do
    create table(:answers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :question_id, references(:questions, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :body, :string, null: false
      add :is_best, :boolean, null: false, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:answers, [:question_id])

    create unique_index(:answers, [:question_id],
             where: "is_best = true",
             name: :answers_one_best_per_question
           )
  end
end
