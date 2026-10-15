defmodule Api.Repo.Migrations.CreateClubChapters do
  use Ecto.Migration

  def change do
    create table(:club_chapters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :club_id, references(:clubs, type: :binary_id, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :label, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:club_chapters, [:club_id, :position])
  end
end
