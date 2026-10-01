defmodule Api.Posts do
  @moduledoc """
  The Posts context: publishing a passage + takeaway + keywords tied to a book (Step 3).
  """

  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Catalog
  alias Api.Posts.{Post, Passage, Keyword, Like}

  @preloads [:book, :passage, :keywords, :user]
  @page_size 20

  def create_post(%User{} = user, attrs) do
    with %Catalog.Book{} = book <- Catalog.get_book(attrs["book_id"]) || {:error, :not_found} do
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
  end

  defp maybe_before(query, before) when is_binary(before) do
    case DateTime.from_iso8601(before) do
      {:ok, cutoff, _offset} -> where(query, [p], p.inserted_at < ^cutoff)
      {:error, _reason} -> query
    end
  end

  defp maybe_before(query, _before), do: query

  def get_post(id, current_user \\ nil) do
    case fetch_post(id) do
      nil -> nil
      post -> post |> Repo.preload(@preloads) |> annotate_liked_one(current_user)
    end
  end

  defp fetch_post(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(Post, uuid)
      :error -> nil
    end
  end

  defp annotate_liked(posts, nil), do: posts

  defp annotate_liked(posts, %User{} = user) do
    liked_ids =
      Like
      |> where([l], l.user_id == ^user.id and l.post_id in ^Enum.map(posts, & &1.id))
      |> select([l], l.post_id)
      |> Repo.all()
      |> MapSet.new()

    Enum.map(posts, fn post -> %{post | liked_by_user: MapSet.member?(liked_ids, post.id)} end)
  end

  defp annotate_liked_one(post, nil), do: post

  defp annotate_liked_one(post, %User{} = user) do
    liked = Repo.exists?(from l in Like, where: l.user_id == ^user.id and l.post_id == ^post.id)
    %{post | liked_by_user: liked}
  end

  @doc """
  Likes a post on behalf of `user`. Idempotent: liking an already-liked post
  just returns the current state instead of inserting a duplicate row.
  """
  def like_post(%User{} = user, post_id) do
    case fetch_post(post_id) do
      nil -> {:error, :not_found}
      post -> do_like(user, post)
    end
  end

  @doc """
  Unlikes a post on behalf of `user`. Idempotent: unliking a post the user
  hasn't liked is a no-op that returns the current state.
  """
  def unlike_post(%User{} = user, post_id) do
    case fetch_post(post_id) do
      nil -> {:error, :not_found}
      post -> do_unlike(user, post)
    end
  end

  defp do_like(user, post) do
    if Repo.get_by(Like, user_id: user.id, post_id: post.id) do
      {:ok, %{liked: true, like_count: post.like_count}}
    else
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(:like, Like.changeset(%Like{}, %{"user_id" => user.id, "post_id" => post.id}))
        |> Ecto.Multi.update_all(:post, fn _ -> where(Post, id: ^post.id) end, inc: [like_count: 1])

      case Repo.transaction(multi) do
        {:ok, _changes} -> {:ok, %{liked: true, like_count: post.like_count + 1}}
        {:error, :like, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  defp do_unlike(user, post) do
    case Repo.get_by(Like, user_id: user.id, post_id: post.id) do
      nil ->
        {:ok, %{liked: false, like_count: post.like_count}}

      like ->
        multi =
          Ecto.Multi.new()
          |> Ecto.Multi.delete(:like, like)
          |> Ecto.Multi.update_all(:post, fn _ -> where(Post, id: ^post.id) end, inc: [like_count: -1])

        {:ok, _changes} = Repo.transaction(multi)
        {:ok, %{liked: false, like_count: max(post.like_count - 1, 0)}}
    end
  end

  defp normalize_keyword_names(names) when is_list(names) do
    names
    |> Enum.map(&normalize_keyword/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_keyword_names(_names), do: []

  defp normalize_keyword(name) when is_binary(name), do: name |> String.trim() |> String.downcase()
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
