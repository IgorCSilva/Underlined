defmodule Api.Repo.Migrations.CreateClubMemberships do
  use Ecto.Migration

  def change do
    create table(:club_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :club_id, references(:clubs, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:club_memberships, [:club_id, :user_id])
    create index(:club_memberships, [:user_id])
  end
end
