defmodule Api.Usecases.Bookmark.UnbookmarkPost.UnbookmarkPostUsecase do
  @moduledoc """
  Unbookmarks a post on behalf of a user. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`. Unlike
  likes and follows, bookmarking has no Community Health pairing, so
  there's no event to enqueue here.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Bookmark.UnbookmarkPost.UnbookmarkPostUsecaseDto

  defstruct [:repository]

  def call(%UnbookmarkPostUsecaseDto{user: %User{} = user, post_id: post_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.unbookmark_post(user, post_id, adaptee)
  end
end
