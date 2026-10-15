defmodule Api.Repo.Migrations.AddGenreAndSeriesToBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :genre, :string
      add :series_name, :string
      add :series_position, :integer
    end

    create index(:books, [:series_name])
  end
end
