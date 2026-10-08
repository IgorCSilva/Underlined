defmodule Api.Repo.Migrations.CreateConnectionComments do
  use Ecto.Migration

  def change do
    create table(:connection_comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :body, :text, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :connection_id, references(:post_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :parent_comment_id,
          references(:connection_comments, type: :binary_id, on_delete: :delete_all),
          null: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:connection_comments, [:connection_id])
    create index(:connection_comments, [:parent_comment_id])
  end
end
