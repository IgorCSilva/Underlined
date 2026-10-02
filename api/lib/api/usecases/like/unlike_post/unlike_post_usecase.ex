defmodule Api.Usecases.Like.UnlikePost.UnlikePostUsecase do
  @moduledoc """
  Unlikes a post on behalf of a user. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Like.UnlikePost.UnlikePostUsecaseDto

  defstruct [:repository]

  def call(%UnlikePostUsecaseDto{user: %User{} = user, post_id: post_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.unlike_post(user, post_id, adaptee)
  end
end
