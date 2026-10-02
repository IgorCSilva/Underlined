defmodule Api.Usecases.Post.ListFollowingPosts.ListFollowingPostsUsecase do
  @moduledoc """
  Chronological feed of posts by users the caller follows, newest first,
  optionally paged backward from a cursor.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Post.ListFollowingPosts.ListFollowingPostsUsecaseDto

  defstruct [:repository]

  def call(%ListFollowingPostsUsecaseDto{user: user, before: before}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_following_posts(user, before, adaptee)
  end
end
