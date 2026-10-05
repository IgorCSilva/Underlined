defmodule Api.Infrastructure.Repository.Post.Postgres.PostRepository do
  @moduledoc """
  Postgres-backed data access for the post entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Book.Postgres.{Book, BookRepository}
  alias Api.Infrastructure.Repository.Bookmark.Postgres.BookmarkRepository
  alias Api.Infrastructure.Repository.Follow.Postgres.Follow
  alias Api.Infrastructure.Repository.Keyword.Postgres.Keyword
  alias Api.Infrastructure.Repository.Like.Postgres.LikeRepository
  alias Api.Infrastructure.Repository.Passage.Postgres.Passage
  alias Api.Infrastructure.Repository.Post.Postgres.Post
  alias Api.Repo

  @preloads [:book, :passage, :keywords, :user]
  @page_size 20

  def create_post(user, attrs) do
    with %Book{} = book <- BookRepository.get_book(attrs["book_id"]) || {:error, :not_found} do
      keyword_names = normalize_keyword_names(attrs["keywords"])

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :passage,
          Passage.changeset(%Passage{}, %{
            "book_id" => book.id,
            "user_id" => user.id,
            "text" => attrs["passage_text"]
          })
        )
        |> Ecto.Multi.insert(:post, fn %{passage: passage} ->
          Post.changeset(%Post{}, %{
            "user_id" => user.id,
            "book_id" => book.id,
            "passage_id" => passage.id,
            "thinking" => attrs["thinking"],
            "keyword_names" => keyword_names
          })
        end)
        |> Ecto.Multi.update(:post_with_keywords, fn %{post: post} ->
          keywords = Enum.map(keyword_names, &get_or_create_keyword/1)

          post
          |> Repo.preload(:keywords)
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:keywords, keywords)
        end)

      case Repo.transaction(multi) do
        {:ok, %{post_with_keywords: post}} -> {:ok, Repo.preload(post, @preloads)}
        {:error, _op, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  @doc """
  Chronological feed, newest first. `before` (an ISO8601 timestamp, usually the
  `inserted_at` of the last post on the previous page) pages backward through
  the feed; invalid/absent cursors just return the first page. `current_user`,
  when given, is used to flag which of the returned posts that user has liked.
  """
  def list_posts(before \\ nil, current_user \\ nil) do
    Post
    |> order_by(desc: :inserted_at)
    |> maybe_before(before)
    |> limit(^@page_size)
    |> Repo.all()
    |> Repo.preload(@preloads)
    |> annotate_liked(current_user)
    |> annotate_bookmarked(current_user)
  end

  defp maybe_before(query, before) when is_binary(before) do
    case DateTime.from_iso8601(before) do
      {:ok, cutoff, _offset} -> where(query, [p], p.inserted_at < ^cutoff)
      {:error, _reason} -> query
    end
  end

  defp maybe_before(query, _before), do: query

  @doc """
  Chronological feed of posts by users that `user` follows, newest first.
  Same `before`-cursor pagination as `list_posts/2`, and likewise annotates
  `liked_by_user` for `user`.
  """
  def list_following_posts(user, before \\ nil) do
    Post
    |> join(:inner, [p], f in Follow,
      on: f.followee_id == p.user_id and f.follower_id == ^user.id
    )
    |> order_by([p], desc: p.inserted_at)
    |> maybe_before(before)
    |> limit(^@page_size)
    |> Repo.all()
    |> Repo.preload(@preloads)
    |> annotate_liked(user)
    |> annotate_bookmarked(user)
  end

  def get_post(id, current_user \\ nil) do
    case fetch_post(id) do
      nil ->
        nil

      post ->
        post
        |> Repo.preload(@preloads)
        |> annotate_liked_one(current_user)
        |> annotate_bookmarked_one(current_user)
    end
  end

  @doc "Fetches a post by id, without preloads. Returns `nil` if missing/invalid."
  def fetch_post(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(Post, uuid)
      :error -> nil
    end
  end

  defp annotate_liked(posts, nil), do: posts

  defp annotate_liked(posts, user) do
    liked_ids = LikeRepository.liked_post_ids(user, Enum.map(posts, & &1.id))

    Enum.map(posts, fn post -> %{post | liked_by_user: MapSet.member?(liked_ids, post.id)} end)
  end

  defp annotate_liked_one(post, nil), do: post

  defp annotate_liked_one(post, user) do
    %{post | liked_by_user: LikeRepository.liked?(user, post.id)}
  end

  defp annotate_bookmarked(posts, nil), do: posts

  defp annotate_bookmarked(posts, user) do
    bookmarked_ids = BookmarkRepository.bookmarked_post_ids(user, Enum.map(posts, & &1.id))

    Enum.map(posts, fn post ->
      %{post | bookmarked_by_user: MapSet.member?(bookmarked_ids, post.id)}
    end)
  end

  defp annotate_bookmarked_one(post, nil), do: post

  defp annotate_bookmarked_one(post, user) do
    %{post | bookmarked_by_user: BookmarkRepository.bookmarked?(user, post.id)}
  end

  defp normalize_keyword_names(names) when is_list(names) do
    names
    |> Enum.map(&normalize_keyword/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_keyword_names(_names), do: []

  defp normalize_keyword(name) when is_binary(name),
    do: name |> String.trim() |> String.downcase()

  defp normalize_keyword(_name), do: ""

  defp get_or_create_keyword(name) do
    case Repo.get_by(Keyword, name: name) do
      nil ->
        {:ok, keyword} = %Keyword{} |> Keyword.changeset(%{name: name}) |> Repo.insert()
        keyword

      keyword ->
        keyword
    end
  end
end
