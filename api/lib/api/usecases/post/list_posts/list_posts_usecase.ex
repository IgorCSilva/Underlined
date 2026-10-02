defmodule Api.Usecases.Post.ListPosts.ListPostsUsecase do
  @moduledoc """
  Chronological post feed, newest first, optionally paged backward from a
  cursor and annotated with whether `current_user` liked each post.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Post.ListPosts.ListPostsUsecaseDto

  defstruct [:repository]

  def call(%ListPostsUsecaseDto{before: before, current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_posts(before, current_user, adaptee)
  end
end
