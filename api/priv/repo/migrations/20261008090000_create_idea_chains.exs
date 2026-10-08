defmodule Api.Repo.Migrations.CreateIdeaChains do
  use Ecto.Migration

  def change do
    create table(:idea_chains, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:idea_chains, [:user_id])

    create table(:idea_chain_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :chain_id, references(:idea_chains, type: :binary_id, on_delete: :delete_all), null: false
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all), null: false

      add :previous_item_id,
          references(:idea_chain_items, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:idea_chain_items, [:chain_id])
    create index(:idea_chain_items, [:post_id])

    # Deferred so a reorder's bulk re-pointing of previous_item_id can pass
    # through intermediate states where two rows briefly share a value
    # (e.g. swapping two adjacent items) without tripping the check before
    # the whole transaction's final state is actually evaluated.
    execute(
      """
      ALTER TABLE idea_chain_items
      ADD CONSTRAINT idea_chain_items_previous_item_id_index
      UNIQUE (previous_item_id) DEFERRABLE INITIALLY DEFERRED
      """,
      "ALTER TABLE idea_chain_items DROP CONSTRAINT idea_chain_items_previous_item_id_index"
    )
  end
end
