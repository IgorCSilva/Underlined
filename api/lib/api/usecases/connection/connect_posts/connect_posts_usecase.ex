defmodule Api.Usecases.Connection.ConnectPosts.ConnectPostsUsecase do
  @moduledoc """
  Links two posts together with a typed relationship, on behalf of a user.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Connection.ConnectPosts.ConnectPostsUsecaseDto

  defstruct [:repository]

  def call(
        %ConnectPostsUsecaseDto{
          user: %User{} = user,
          post_id: post_id,
          related_post_id: related_post_id,
          relationship_type: relationship_type
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.connect_posts(user, post_id, related_post_id, relationship_type, adaptee)
  end
end
