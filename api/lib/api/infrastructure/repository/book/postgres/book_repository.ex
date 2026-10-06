defmodule Api.Infrastructure.Repository.Book.Postgres.BookRepository do
  @moduledoc """
  Postgres-backed data access for the book entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Book.Postgres.Book
  alias Api.Infrastructure.Repository.Bookmark.Postgres.BookmarkRepository
  alias Api.Infrastructure.Repository.Like.Postgres.LikeRepository
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Repo

  @list_limit 50
  @post_preloads [:book, :passage, :keywords, :user]
  @page_size 20
  @cache :book_page_cache
  @cache_ttl :timer.minutes(1)

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

  @doc """
  Looks up a book by id together with its stats (post/reader counts) and a
  page of posts about it (same `before`-cursor pagination as
  `PostRepository.list_posts/2`). Returns `{:error, :not_found}` when no
  book has that id.

  Stats don't depend on `before` or the current user, so they're cached
  briefly per book — the expensive, read-heavy part of a public page. The
  post list itself is always queried fresh and annotated for
  `current_user`, since `liked_by_user`/`bookmarked_by_user` must never be
  shared across users.
  """
  def get_book_page(id, before, current_user) do
    case get_book(id) do
      nil ->
        {:error, :not_found}

      book ->
        stats = fetch_stats(book)

        posts =
          book
          |> list_posts_by_book(before)
          |> Repo.preload(@post_preloads)
          |> annotate_liked(current_user)
          |> annotate_bookmarked(current_user)

        {:ok, %{book: book, stats: stats, posts: posts}}
    end
  end

  # Cachex.fetch/3 would run the DB query inside its own courier process (to
  # dedupe concurrent misses), which breaks the Ecto Sandbox's per-test
  # connection ownership in tests. A plain get-then-put keeps the query on
  # the caller's process instead.
  defp fetch_stats(book) do
    case Cachex.get(@cache, book.id) do
      {:ok, nil} ->
        stats = build_stats(book)
        Cachex.put(@cache, book.id, stats, ttl: @cache_ttl)
        stats

      {:ok, stats} ->
        stats
    end
  end

  defp build_stats(book) do
    Repo.one(
      from p in Post,
        where: p.book_id == ^book.id,
        select: %{
          post_count: count(p.id, :distinct),
          reader_count: count(p.user_id, :distinct)
        }
    )
  end

  defp list_posts_by_book(book, before) do
    Post
    |> where([p], p.book_id == ^book.id)
    |> order_by([p], desc: p.inserted_at)
    |> maybe_before(before)
    |> limit(^@page_size)
    |> Repo.all()
  end

  defp maybe_before(query, before) when is_binary(before) do
    case DateTime.from_iso8601(before) do
      {:ok, cutoff, _offset} -> where(query, [p], p.inserted_at < ^cutoff)
      {:error, _reason} -> query
    end
  end

  defp maybe_before(query, _before), do: query

  defp annotate_liked(posts, nil), do: posts

  defp annotate_liked(posts, user) do
    liked_ids = LikeRepository.liked_post_ids(user, Enum.map(posts, & &1.id))

    Enum.map(posts, fn post -> %{post | liked_by_user: MapSet.member?(liked_ids, post.id)} end)
  end

  defp annotate_bookmarked(posts, nil), do: posts

  defp annotate_bookmarked(posts, user) do
    bookmarked_ids = BookmarkRepository.bookmarked_post_ids(user, Enum.map(posts, & &1.id))

    Enum.map(posts, fn post ->
      %{post | bookmarked_by_user: MapSet.member?(bookmarked_ids, post.id)}
    end)
  end
end
