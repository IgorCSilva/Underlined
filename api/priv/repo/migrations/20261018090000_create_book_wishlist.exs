defmodule Api.Repo.Migrations.CreateBookWishlist do
  use Ecto.Migration

  def change do
    create table(:book_wishlist, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :book_id, references(:books, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:book_wishlist, [:user_id, :book_id])
    create index(:book_wishlist, [:book_id])
  end
end
