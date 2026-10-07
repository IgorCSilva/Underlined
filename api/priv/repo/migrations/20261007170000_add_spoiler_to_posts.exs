defmodule Api.Repo.Migrations.AddSpoilerToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :spoiler, :boolean, null: false, default: false
    end
  end
end
