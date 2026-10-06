defmodule Api.Usecases.Follow.UnfollowUser.UnfollowUserUsecase do
  @moduledoc """
  Unfollows a user on behalf of another user. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to record the UNFOLLOW event —
  this usecase never aliases an Infrastructure module directly.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Follow.UnfollowUser.UnfollowUserUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(
        %UnfollowUserUsecaseDto{follower: %User{} = follower, followee_id: followee_id},
        %__MODULE__{
          repository: %{adapter: adapter, adaptee: adaptee},
          community_health_enqueuer: enqueue_community_health
        }
      ) do
    with {:ok, result} <- adapter.unfollow_user(follower, followee_id, adaptee) do
      enqueue_community_health.(%{
        action: "record_action",
        actor_id: follower.id,
        action_type: "UNFOLLOW",
        resource_type: "actor",
        resource_id: followee_id,
        community_id: default_community_id(),
        event_key:
          "follow:remove:#{follower.id}:#{followee_id}:#{System.system_time(:microsecond)}"
      })

      {:ok, result}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
