defmodule Api.Usecases.Like.LikePost.LikePostUsecase do
  @moduledoc """
  Likes a post on behalf of a user. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Like.LikePost.LikePostUsecaseDto

  defstruct [:repository]

  def call(%LikePostUsecaseDto{user: %User{} = user, post_id: post_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.like_post(user, post_id, adaptee)
  end
end
