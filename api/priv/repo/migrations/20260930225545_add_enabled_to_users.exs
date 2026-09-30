defmodule Api.Repo.Migrations.AddEnabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :enabled, :boolean, null: false, default: false
    end
  end
end
