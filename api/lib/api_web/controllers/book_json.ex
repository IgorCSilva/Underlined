defmodule ApiWeb.BookJSON do
  alias Api.Domain.Book
  alias ApiWeb.PostJSON
  alias ApiWeb.QuestionJSON

  def index(%{books: books}), do: %{data: Enum.map(books, &data/1)}

  def show(%{book: book}), do: %{data: data(book)}

  def genres(%{genres: genres}), do: %{data: genres}

  def page(%{page: page}) do
    %{
      data:
        Map.merge(data(page.book), %{
          stats: page.stats,
          posts: Enum.map(page.posts, &PostJSON.data/1),
          questions: Enum.map(page.questions, &QuestionJSON.data/1)
        })
    }
  end

  def data(%Book{} = book) do
    %{
      id: book.id,
      title: book.title,
      author: book.author,
      cover_url: book.cover_url,
      genres: book.genres,
      series_name: book.series_name,
      series_position: book.series_position
    }
  end
end
