defmodule Api.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :author, :string, null: false
      add :cover_url, :string

      # usec precision (unlike users' :utc_datetime) so list_books/1's
      # "newest first" ordering has a stable tiebreak for rows inserted
      # within the same second.
      timestamps(type: :utc_datetime_usec)
    end

    execute(
      "CREATE INDEX books_search_idx ON books USING GIN (to_tsvector('english', title || ' ' || author))",
      "DROP INDEX books_search_idx"
    )
  end
end
