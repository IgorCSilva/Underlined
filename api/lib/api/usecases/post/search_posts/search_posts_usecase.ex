defmodule Api.Usecases.Post.SearchPosts.SearchPostsUsecase do
  @moduledoc """
  Posts whose book title or thinking matches `search`, newest first, across
  every author — backs pickers like "connect to another post" and "add to
  chain" that need to find a post anywhere on the platform, not just among
  the most recent ones.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Post.SearchPosts.SearchPostsUsecaseDto

  defstruct [:repository]

  def call(%SearchPostsUsecaseDto{search: search, current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.search_posts(search, current_user, adaptee)
  end
end
