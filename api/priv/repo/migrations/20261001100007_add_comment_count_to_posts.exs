defmodule Api.Repo.Migrations.AddCommentCountToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :comment_count, :integer, null: false, default: 0
    end
  end
end
