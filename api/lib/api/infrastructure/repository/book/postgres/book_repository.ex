defmodule Api.Infrastructure.Repository.Book.Postgres.BookRepository do
  @moduledoc """
  Postgres-backed data access for the book entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Repo

  @list_limit 50

  def list_books(query) when is_binary(query) do
    trimmed = String.trim(query)

    if trimmed == "" do
      list_books(nil)
    else
      Book
      |> where(
        [b],
        fragment(
          "to_tsvector('english', ? || ' ' || ?) @@ plainto_tsquery('english', ?)",
          b.title,
          b.author,
          ^trimmed
        )
      )
      |> order_by(
        [b],
        desc:
          fragment(
            "ts_rank(to_tsvector('english', ? || ' ' || ?), plainto_tsquery('english', ?))",
            b.title,
            b.author,
            ^trimmed
          )
      )
      |> limit(^@list_limit)
      |> Repo.all()
    end
  end

  def list_books(_query) do
    Book
    |> order_by(desc: :inserted_at)
    |> limit(^@list_limit)
    |> Repo.all()
  end

  def get_book(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(Book, uuid)
      :error -> nil
    end
  end

  @doc """
  Adds a book, or returns the existing one if a book with the same
  title/author (case-insensitive) already exists.
  """
  def add_book(attrs) do
    title = attrs["title"] || attrs[:title]
    author = attrs["author"] || attrs[:author]

    case find_existing(title, author) do
      nil -> %Book{} |> Book.changeset(attrs) |> Repo.insert()
      book -> {:ok, book}
    end
  end

  defp find_existing(title, author) when is_binary(title) and is_binary(author) do
    Repo.one(
      from b in Book,
        where:
          fragment("lower(?) = lower(?)", b.title, ^title) and
            fragment("lower(?) = lower(?)", b.author, ^author)
    )
  end

  defp find_existing(_title, _author), do: nil
end
