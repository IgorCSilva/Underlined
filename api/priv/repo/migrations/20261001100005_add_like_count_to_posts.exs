defmodule Api.Repo.Migrations.AddLikeCountToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :like_count, :integer, null: false, default: 0
    end
  end
end
