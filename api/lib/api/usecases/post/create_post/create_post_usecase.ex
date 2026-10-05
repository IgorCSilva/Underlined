defmodule Api.Usecases.Post.CreatePost.CreatePostUsecase do
  @moduledoc """
  Publishes a passage + takeaway + keywords tied to a book.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to record the publish event —
  this usecase never aliases an Infrastructure module directly.
  """

  alias Api.Usecases.Post.CreatePost.CreatePostUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(%CreatePostUsecaseDto{user: user, attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee},
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, post} <- adapter.create_post(user, attrs, adaptee) do
      # event_key is idempotent on the post's own id, so a retry or the
      # one-time backfill (mix community_health.backfill_posts) can never
      # double-record the same post.
      enqueue_community_health.(%{
        action: "record_action",
        actor_id: user.id,
        action_type: "CREATE",
        resource_type: "post",
        resource_id: post.id,
        community_id: default_community_id(),
        event_key: "post:create:#{post.id}"
      })

      {:ok, post}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
