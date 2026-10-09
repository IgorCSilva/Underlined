defmodule Api.Repo.Migrations.CreatePostConnections do
  use Ecto.Migration

  def change do
    create table(:post_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :relationship_type, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all), null: false

      add :related_post_id, references(:posts, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:post_connections, [:post_id, :related_post_id, :relationship_type])
    create index(:post_connections, [:related_post_id])
  end
end
