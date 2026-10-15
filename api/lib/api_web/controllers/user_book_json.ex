defmodule ApiWeb.UserBookJSON do
  alias Api.Domain.UserBook
  alias ApiWeb.BookJSON

  def show(%{user_book: user_book}), do: %{data: data(user_book)}

  def index(%{user_books: user_books}), do: %{data: Enum.map(user_books, &data/1)}

  def data(%UserBook{} = user_book) do
    %{
      id: user_book.id,
      status: user_book.status,
      book: BookJSON.data(user_book.book)
    }
  end
end
