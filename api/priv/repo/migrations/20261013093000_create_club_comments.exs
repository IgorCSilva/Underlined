defmodule Api.Repo.Migrations.CreateClubComments do
  use Ecto.Migration

  def change do
    create table(:club_comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :body, :text, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :club_post_id, references(:club_posts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :parent_comment_id,
          references(:club_comments, type: :binary_id, on_delete: :delete_all),
          null: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:club_comments, [:club_post_id])
    create index(:club_comments, [:parent_comment_id])
  end
end
