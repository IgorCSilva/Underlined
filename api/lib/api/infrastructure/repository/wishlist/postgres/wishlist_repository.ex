defmodule Api.Infrastructure.Repository.Wishlist.Postgres.WishlistRepository do
  @moduledoc """
  Postgres-backed data access for a user's wishlist: which books they
  want, independent of any shelf status.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Book.Postgres.BookRepository
  alias Api.Infrastructure.Repository.Wishlist.Postgres.Wishlist
  alias Api.Repo

  @doc """
  Adds `book_id` to `user`'s wishlist. Idempotent: wishlisting an
  already-wishlisted book just returns the current state instead of
  inserting a duplicate row. Returns `{:error, :not_found}` when no book
  has that id.
  """
  def add_to_wishlist(user, book_id) do
    case BookRepository.get_book(book_id) do
      nil -> {:error, :not_found}
      _book -> do_add(user, book_id)
    end
  end

  @doc """
  Removes `book_id` from `user`'s wishlist. Idempotent: removing a book
  that isn't wishlisted is a no-op that returns the current state.
  """
  def remove_from_wishlist(user, book_id) do
    case BookRepository.get_book(book_id) do
      nil -> {:error, :not_found}
      _book -> do_remove(user, book_id)
    end
  end

  @doc """
  Every book on `user_id`'s wishlist, most recently wishlisted first,
  each with its book preloaded.
  """
  def list_wishlist(user_id) do
    case Ecto.UUID.cast(user_id) do
      {:ok, uuid} ->
        Wishlist
        |> where([w], w.user_id == ^uuid)
        |> order_by(desc: :inserted_at)
        |> Repo.all()
        |> Repo.preload(:book)

      :error ->
        []
    end
  end

  defp do_add(user, book_id) do
    case Repo.get_by(Wishlist, user_id: user.id, book_id: book_id) do
      nil ->
        %Wishlist{}
        |> Wishlist.changeset(%{"user_id" => user.id, "book_id" => book_id})
        |> Repo.insert()
        |> case do
          {:ok, _item} -> {:ok, %{wishlisted: true}}
          {:error, changeset} -> {:error, changeset}
        end

      _item ->
        {:ok, %{wishlisted: true}}
    end
  end

  defp do_remove(user, book_id) do
    case Repo.get_by(Wishlist, user_id: user.id, book_id: book_id) do
      nil ->
        {:ok, %{wishlisted: false}}

      item ->
        Repo.delete!(item)
        {:ok, %{wishlisted: false}}
    end
  end
end
