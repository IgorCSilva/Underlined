defmodule Api.Repo.Migrations.WidenPassagesText do
  use Ecto.Migration

  # The original migration declared `:text, :string` with no explicit size,
  # which Ecto maps to `varchar(255)` in Postgres. That's unrelated to the
  # changeset's `validate_length` cap, so any passage between 256 chars and
  # the changeset's max slipped past Ecto validation and crashed as a raw
  # Postgrex string-truncation error instead of a 422. Switching to `:text`
  # removes the DB-side cap entirely, leaving the changeset as the single
  # source of truth for the business limit.
  def change do
    alter table(:passages) do
      modify :text, :text, null: false
    end
  end
end
