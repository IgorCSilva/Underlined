defmodule Api.Usecases.Like.UnlikePost.UnlikePostUsecase do
  @moduledoc """
  Unlikes a post on behalf of a user. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to record the UNREACT event —
  this usecase never aliases an Infrastructure module directly.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Like.UnlikePost.UnlikePostUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(%UnlikePostUsecaseDto{user: %User{} = user, post_id: post_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee},
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, result} <- adapter.unlike_post(user, post_id, adaptee) do
      enqueue_community_health.(%{
        action: "record_action",
        actor_id: user.id,
        action_type: "UNREACT",
        resource_type: "post",
        resource_id: post_id,
        community_id: default_community_id(),
        event_key: "post:unreact:#{user.id}:#{post_id}:#{System.system_time(:microsecond)}"
      })

      {:ok, result}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
