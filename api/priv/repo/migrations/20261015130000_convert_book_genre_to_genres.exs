defmodule Api.Repo.Migrations.ConvertBookGenreToGenres do
  use Ecto.Migration

  def change do
    alter table(:books) do
      remove :genre, :string
      add :genres, {:array, :string}, null: false, default: []
    end
  end
end
