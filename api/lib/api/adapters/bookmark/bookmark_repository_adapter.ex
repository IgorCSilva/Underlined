defmodule Api.Adapters.Bookmark.BookmarkRepositoryAdapter do
  @moduledoc """
  Adapts a bookmark repository (the adaptee) to the usecase layer. The
  toggle actions pass the resulting bookmarked? state straight through;
  listing bookmarked posts converts each result into the pure
  `Api.Domain.Post` business entity, same as `Api.Adapters.Post.PostRepositoryAdapter`.
  """

  alias Api.Adapters.Post.PostRepositoryAdapter

  def bookmark_post(user, post_id, adaptee), do: adaptee.bookmark_post(user, post_id)

  def unbookmark_post(user, post_id, adaptee), do: adaptee.unbookmark_post(user, post_id)

  def list_bookmarked_posts(user, before, adaptee) do
    adaptee.list_bookmarked_posts(user, before) |> Enum.map(&PostRepositoryAdapter.to_domain/1)
  end
end
