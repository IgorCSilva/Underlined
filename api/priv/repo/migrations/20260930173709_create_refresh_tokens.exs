defmodule Api.Repo.Migrations.CreateRefreshTokens do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token_hash, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :remember_me, :boolean, null: false, default: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:refresh_tokens, [:user_id])
    create unique_index(:refresh_tokens, [:token_hash])
  end
end
