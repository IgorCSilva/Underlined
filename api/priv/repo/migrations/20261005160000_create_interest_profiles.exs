defmodule Api.Repo.Migrations.CreateInterestProfiles do
  use Ecto.Migration

  def change do
    create table(:interest_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :keyword_id, references(:keywords, type: :binary_id, on_delete: :delete_all), null: false
      add :post_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:interest_profiles, [:user_id, :keyword_id])
    create index(:interest_profiles, [:keyword_id])
  end
end
