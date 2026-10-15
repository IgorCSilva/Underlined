defmodule Api.Adapters.UserBook.UserBookRepositoryAdapter do
  @moduledoc """
  Adapts a user-book repository (the adaptee) to the domain: calls it for
  the database entity/entities, then converts the result(s) into the
  pure Api.Domain.UserBook business entity.
  """

  alias Api.Adapters.Book.BookRepositoryAdapter
  alias Api.Domain.UserBook, as: DomainUserBook

  def set_status(user, book_id, status, adaptee) do
    case adaptee.set_status(user, book_id, status) do
      {:ok, db_user_book} -> {:ok, to_domain(db_user_book)}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_user_books(user_id, adaptee) do
    adaptee.list_user_books(user_id) |> Enum.map(&to_domain/1)
  end

  @doc "Converts a Postgres user-book entity (with :book preloaded) into the pure domain entity."
  def to_domain(db_user_book) do
    %DomainUserBook{
      id: db_user_book.id,
      status: db_user_book.status,
      book: BookRepositoryAdapter.to_domain(db_user_book.book),
      inserted_at: db_user_book.inserted_at,
      updated_at: db_user_book.updated_at
    }
  end
end
