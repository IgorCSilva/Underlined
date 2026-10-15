defmodule Api.Repo.Migrations.AddChapterFieldsToClubs do
  use Ecto.Migration

  def change do
    alter table(:clubs) do
      add :chapter_unit_label, :string, null: false, default: "Chapter"

      add :current_chapter_id,
          references(:club_chapters, type: :binary_id, on_delete: :nilify_all),
          null: true
    end
  end
end
