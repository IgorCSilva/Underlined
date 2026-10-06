defmodule Api.Usecases.Comment.CreateComment.CreateCommentUsecase do
  @moduledoc """
  Creates a top-level comment (no `parent_comment_id`) or a reply (one
  level deep only) on a post.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to record the COMMENT event —
  this usecase never aliases an Infrastructure module directly.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Comment.CreateComment.CreateCommentUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(
        %CreateCommentUsecaseDto{user: %User{} = user, post_id: post_id, attrs: attrs},
        %__MODULE__{
          repository: %{adapter: adapter, adaptee: adaptee},
          community_health_enqueuer: enqueue_community_health
        }
      ) do
    with {:ok, comment} <- adapter.create_comment(user, post_id, attrs, adaptee) do
      # event_key is idempotent on the comment's own id, same reasoning as
      # CreatePostUsecase's `post:create:` key: a comment is only ever
      # created once, unlike a like's toggleable REACT/UNREACT pair.
      enqueue_community_health.(%{
        action: "record_action",
        actor_id: user.id,
        action_type: "COMMENT",
        resource_type: "comment",
        resource_id: comment.id,
        community_id: default_community_id(),
        event_key: "comment:create:#{comment.id}",
        context: %{parent_type: comment.type}
      })

      {:ok, comment}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
