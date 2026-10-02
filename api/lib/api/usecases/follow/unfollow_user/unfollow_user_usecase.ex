defmodule Api.Usecases.Follow.UnfollowUser.UnfollowUserUsecase do
  @moduledoc """
  Unfollows a user on behalf of another user. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Follow.UnfollowUser.UnfollowUserUsecaseDto

  defstruct [:repository]

  def call(
        %UnfollowUserUsecaseDto{follower: %User{} = follower, followee_id: followee_id},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.unfollow_user(follower, followee_id, adaptee)
  end
end
