defmodule Api.Repo.Migrations.CreateKeywords do
  use Ecto.Migration

  def change do
    create table(:keywords, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:keywords, [:name])
  end
end
