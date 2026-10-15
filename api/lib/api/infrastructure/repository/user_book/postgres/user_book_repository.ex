defmodule Api.Infrastructure.Repository.UserBook.Postgres.UserBookRepository do
  @moduledoc """
  Postgres-backed data access for a user's bookcase: which books they've
  shelved, and under which reading status.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Book.Postgres.BookRepository
  alias Api.Infrastructure.Repository.UserBook.Postgres.UserBook
  alias Api.Repo

  @doc """
  Shelves `book_id` onto `user`'s bookcase under `status`
  (to_read/reading/read), or moves it there if already shelved. Upserts
  the one row per user+book. Returns `{:error, :not_found}` when no book
  has that id, or `{:error, changeset}` for an invalid status.
  """
  def set_status(user, book_id, status) do
    case BookRepository.get_book(book_id) do
      nil ->
        {:error, :not_found}

      _book ->
        existing = Repo.get_by(UserBook, user_id: user.id, book_id: book_id)

        (existing || %UserBook{})
        |> UserBook.changeset(%{"user_id" => user.id, "book_id" => book_id, "status" => status})
        |> Repo.insert_or_update()
        |> case do
          {:ok, user_book} -> {:ok, Repo.preload(user_book, :book)}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Every book on `user_id`'s bookcase, most recently shelved/moved first,
  each with its book preloaded.
  """
  def list_user_books(user_id) do
    case Ecto.UUID.cast(user_id) do
      {:ok, uuid} ->
        UserBook
        |> where([ub], ub.user_id == ^uuid)
        |> order_by(desc: :updated_at)
        |> Repo.all()
        |> Repo.preload(:book)

      :error ->
        []
    end
  end
end
