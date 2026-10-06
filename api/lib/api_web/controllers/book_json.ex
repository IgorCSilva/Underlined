defmodule ApiWeb.BookJSON do
  alias Api.Domain.Book
  alias ApiWeb.PostJSON

  def index(%{books: books}), do: %{data: Enum.map(books, &data/1)}

  def show(%{book: book}), do: %{data: data(book)}

  def page(%{page: page}) do
    %{
      data:
        Map.merge(data(page.book), %{
          stats: page.stats,
          posts: Enum.map(page.posts, &PostJSON.data/1)
        })
    }
  end

  def data(%Book{} = book) do
    %{
      id: book.id,
      title: book.title,
      author: book.author,
      cover_url: book.cover_url
    }
  end
end
