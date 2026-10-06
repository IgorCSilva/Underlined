defmodule Api.Usecases.Bookmark.ListBookmarkedPosts.ListBookmarkedPostsUsecase do
  @moduledoc """
  Reverse-chronological list of posts the caller has bookmarked, optionally
  paged backward from a cursor.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Bookmark.ListBookmarkedPosts.ListBookmarkedPostsUsecaseDto

  defstruct [:repository]

  def call(%ListBookmarkedPostsUsecaseDto{user: user, before: before}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_bookmarked_posts(user, before, adaptee)
  end
end
