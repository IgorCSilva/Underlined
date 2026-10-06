defmodule Api.Usecases.Post.RelatedPosts.RelatedPostsUsecase do
  @moduledoc """
  Other posts that share at least one keyword with a post, most-overlap
  first. Returns `{:error, :not_found}` when the post doesn't exist.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Post.RelatedPosts.RelatedPostsUsecaseDto

  defstruct [:repository]

  def call(%RelatedPostsUsecaseDto{id: id, current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.related_posts(id, current_user, adaptee)
  end
end
