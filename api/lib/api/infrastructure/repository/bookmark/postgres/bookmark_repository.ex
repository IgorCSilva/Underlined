defmodule Api.Infrastructure.Repository.Bookmark.Postgres.BookmarkRepository do
  @moduledoc """
  Postgres-backed data access for the bookmark entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Bookmark.Postgres.Bookmark
  alias Api.Infrastructure.Repository.Like.Postgres.LikeRepository
  alias Api.Infrastructure.Repository.Post.Postgres.{Post, PostRepository}
  alias Api.Repo

  @preloads [:book, :passage, :keywords, :user]
  @page_size 20

  @doc "Returns the set of post ids, among `post_ids`, that `user` has bookmarked."
  def bookmarked_post_ids(user, post_ids) do
    Bookmark
    |> where([b], b.user_id == ^user.id and b.post_id in ^post_ids)
    |> select([b], b.post_id)
    |> Repo.all()
    |> MapSet.new()
  end

  def bookmarked?(user, post_id) do
    Repo.exists?(from b in Bookmark, where: b.user_id == ^user.id and b.post_id == ^post_id)
  end

  @doc """
  Bookmarks the post `post_id` on behalf of `user`. Idempotent: bookmarking
  an already-bookmarked post just returns the current state instead of
  inserting a duplicate row.
  """
  def bookmark_post(user, post_id) do
    case PostRepository.fetch_post(post_id) do
      nil -> {:error, :not_found}
      _post -> do_bookmark(user, post_id)
    end
  end

  @doc """
  Removes the bookmark on post `post_id` on behalf of `user`. Idempotent:
  unbookmarking a post the user hasn't bookmarked is a no-op.
  """
  def unbookmark_post(user, post_id) do
    case PostRepository.fetch_post(post_id) do
      nil -> {:error, :not_found}
      _post -> do_unbookmark(user, post_id)
    end
  end

  @doc """
  Reverse-chronological list (by post creation time, same cursor semantics
  as `PostRepository.list_posts/2`) of posts `user` has bookmarked.
  """
  def list_bookmarked_posts(user, before \\ nil) do
    Post
    |> join(:inner, [p], b in Bookmark, on: b.post_id == p.id and b.user_id == ^user.id)
    |> order_by([p], desc: p.inserted_at)
    |> maybe_before(before)
    |> limit(^@page_size)
    |> Repo.all()
    |> Repo.preload(@preloads)
    |> annotate(user)
  end

  defp maybe_before(query, before) when is_binary(before) do
    case DateTime.from_iso8601(before) do
      {:ok, cutoff, _offset} -> where(query, [p], p.inserted_at < ^cutoff)
      {:error, _reason} -> query
    end
  end

  defp maybe_before(query, _before), do: query

  defp annotate(posts, user) do
    liked_ids = LikeRepository.liked_post_ids(user, Enum.map(posts, & &1.id))

    Enum.map(posts, fn post ->
      %{post | liked_by_user: MapSet.member?(liked_ids, post.id), bookmarked_by_user: true}
    end)
  end

  defp do_bookmark(user, post_id) do
    case Repo.get_by(Bookmark, user_id: user.id, post_id: post_id) do
      nil ->
        %Bookmark{}
        |> Bookmark.changeset(%{"user_id" => user.id, "post_id" => post_id})
        |> Repo.insert()
        |> case do
          {:ok, _bookmark} -> {:ok, %{bookmarked: true}}
          {:error, changeset} -> {:error, changeset}
        end

      _bookmark ->
        {:ok, %{bookmarked: true}}
    end
  end

  defp do_unbookmark(user, post_id) do
    case Repo.get_by(Bookmark, user_id: user.id, post_id: post_id) do
      nil -> {:ok, %{bookmarked: false}}
      bookmark ->
        Repo.delete!(bookmark)
        {:ok, %{bookmarked: false}}
    end
  end
end
