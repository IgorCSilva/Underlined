defmodule Api.Repo.Migrations.AddSideToConnectionComments do
  use Ecto.Migration

  def change do
    alter table(:connection_comments) do
      add :side, :string, null: false, default: "neutral"
    end
  end
end
