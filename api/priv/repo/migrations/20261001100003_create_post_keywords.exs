defmodule Api.Repo.Migrations.CreatePostKeywords do
  use Ecto.Migration

  def change do
    create table(:post_keywords, primary_key: false) do
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all), null: false

      add :keyword_id, references(:keywords, type: :binary_id, on_delete: :delete_all),
        null: false
    end

    create unique_index(:post_keywords, [:post_id, :keyword_id])
    create index(:post_keywords, [:keyword_id])
  end
end
