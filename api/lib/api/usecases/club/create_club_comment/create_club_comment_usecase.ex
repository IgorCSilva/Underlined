defmodule Api.Usecases.Club.CreateClubComment.CreateClubCommentUsecase do
  @moduledoc """
  Creates a top-level comment (no `parent_comment_id`) or a reply (one
  level deep only) on the discussion thread scoped to a club post. Only
  an existing member of the post's club may comment — enforced by the
  repository.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.CreateClubComment.CreateClubCommentUsecaseDto

  defstruct [:repository]

  def call(
        %CreateClubCommentUsecaseDto{user: user, club_post_id: club_post_id, attrs: attrs},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.create_comment(user, club_post_id, attrs, adaptee)
  end
end
