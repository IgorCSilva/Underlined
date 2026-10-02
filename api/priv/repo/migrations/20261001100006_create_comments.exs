defmodule Api.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :body, :text, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all), null: false

      add :parent_comment_id, references(:comments, type: :binary_id, on_delete: :delete_all),
        null: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:comments, [:post_id])
    create index(:comments, [:parent_comment_id])
  end
end
