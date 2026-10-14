defmodule Api.Repo.Migrations.AddTargetDateToClubChapters do
  use Ecto.Migration

  def change do
    alter table(:club_chapters) do
      add :target_date, :date
    end
  end
end
