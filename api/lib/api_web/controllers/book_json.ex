defmodule ApiWeb.BookJSON do
  alias Api.Catalog.Book

  def index(%{books: books}), do: %{data: Enum.map(books, &data/1)}

  def show(%{book: book}), do: %{data: data(book)}

  def data(%Book{} = book) do
    %{
      id: book.id,
      title: book.title,
      author: book.author,
      cover_url: book.cover_url
    }
  end
end
