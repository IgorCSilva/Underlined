defmodule Api.Adapters.Book.BookRepositoryAdapter do
  @moduledoc """
  Adapts a book repository (the adaptee) to the domain: calls it for the
  database entity/entities, then converts the result(s) into the pure
  Api.Domain.Book business entity.
  """

  alias Api.Adapters.Post.PostRepositoryAdapter
  alias Api.Domain.Book, as: DomainBook

  def list_books(query, adaptee), do: adaptee.list_books(query) |> Enum.map(&to_domain/1)

  def get_book(id, adaptee) do
    case adaptee.get_book(id) do
      nil -> nil
      db_book -> to_domain(db_book)
    end
  end

  def add_book(attrs, adaptee) do
    case adaptee.add_book(attrs) do
      {:ok, db_book} -> {:ok, to_domain(db_book)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Fetches the book page (book, stats, posts) and converts every nested
  entity into its pure domain form.
  """
  def get_book_page(id, before, current_user, adaptee) do
    case adaptee.get_book_page(id, before, current_user) do
      {:error, :not_found} ->
        {:error, :not_found}

      {:ok, %{book: book, stats: stats, posts: posts}} ->
        {:ok,
         %{
           book: to_domain(book),
           stats: stats,
           posts: Enum.map(posts, &PostRepositoryAdapter.to_domain/1)
         }}
    end
  end

  @doc "Converts a Postgres book entity into the pure domain entity."
  def to_domain(db_book) do
    %DomainBook{
      id: db_book.id,
      title: db_book.title,
      author: db_book.author,
      cover_url: db_book.cover_url,
      inserted_at: db_book.inserted_at,
      updated_at: db_book.updated_at
    }
  end
end
