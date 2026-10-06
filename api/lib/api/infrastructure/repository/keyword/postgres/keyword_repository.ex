defmodule Api.Infrastructure.Repository.Keyword.Postgres.KeywordRepository do
  @moduledoc """
  Postgres-backed data access for the keyword page: a keyword's stats
  (posts/books/readers), the other keywords it co-occurs with, and the
  paginated list of posts tagged with it.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Bookmark.Postgres.BookmarkRepository
  alias Api.Infrastructure.Repository.Keyword.Postgres.Keyword
  alias Api.Infrastructure.Repository.Like.Postgres.LikeRepository
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Repo

  @preloads [:book, :passage, :keywords, :user]
  @page_size 20
  @related_limit 8
  @cache :keyword_page_cache
  @cache_ttl :timer.minutes(1)

  @doc """
  Looks up a keyword by name (same trim+downcase normalization used when
  posts are created) together with its stats, related keywords, and a page
  of its posts (same `before`-cursor pagination as `PostRepository.list_posts/2`).
  Returns `{:error, :not_found}` when no keyword has that name.

  Stats and related keywords don't depend on `before` or the current user,
  so they're cached briefly per keyword — the expensive, read-heavy part of
  a public page. The post list itself is always queried fresh and annotated
  for `current_user`, since `liked_by_user`/`bookmarked_by_user` must never
  be shared across users.
  """
  def get_keyword_page(name, before, current_user) do
    case find_by_name(name) do
      nil ->
        {:error, :not_found}

      keyword ->
        %{stats: stats, related: related} = fetch_meta(keyword)

        posts =
          keyword
          |> list_posts_by_keyword(before)
          |> Repo.preload(@preloads)
          |> annotate_liked(current_user)
          |> annotate_bookmarked(current_user)

        {:ok, %{keyword: keyword, stats: stats, related: related, posts: posts}}
    end
  end

  def find_by_name(name) do
    Repo.get_by(Keyword, name: normalize(name))
  end

  # Cachex.fetch/3 would run the DB query inside its own courier process (to
  # dedupe concurrent misses), which breaks the Ecto Sandbox's per-test
  # connection ownership in tests. A plain get-then-put keeps the query on
  # the caller's process instead.
  defp fetch_meta(keyword) do
    case Cachex.get(@cache, keyword.id) do
      {:ok, nil} ->
        meta = build_meta(keyword)
        Cachex.put(@cache, keyword.id, meta, ttl: @cache_ttl)
        meta

      {:ok, meta} ->
        meta
    end
  end

  defp build_meta(keyword) do
    %{stats: stats(keyword), related: related_keywords(keyword)}
  end

  defp stats(keyword) do
    Repo.one(
      from pk in "post_keywords",
        join: p in Post,
        on: p.id == pk.post_id,
        where: pk.keyword_id == type(^keyword.id, Ecto.UUID),
        select: %{
          post_count: count(p.id, :distinct),
          book_count: count(p.book_id, :distinct),
          reader_count: count(p.user_id, :distinct)
        }
    )
  end

  defp related_keywords(keyword) do
    Repo.all(
      from k in Keyword,
        join: pk2 in "post_keywords",
        on: pk2.keyword_id == k.id,
        join: pk1 in "post_keywords",
        on: pk1.post_id == pk2.post_id,
        where: pk1.keyword_id == type(^keyword.id, Ecto.UUID) and k.id != ^keyword.id,
        group_by: k.id,
        order_by: [desc: count(pk2.post_id)],
        limit: ^@related_limit,
        select: k
    )
  end

  defp list_posts_by_keyword(keyword, before) do
    Post
    |> join(:inner, [p], pk in "post_keywords",
      on: pk.post_id == p.id and pk.keyword_id == type(^keyword.id, Ecto.UUID)
    )
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

  defp normalize(name) when is_binary(name), do: name |> String.trim() |> String.downcase()
  defp normalize(_name), do: ""
end
