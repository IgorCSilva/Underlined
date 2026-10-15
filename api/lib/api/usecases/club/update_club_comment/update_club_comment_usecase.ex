defmodule Api.Usecases.Club.UpdateClubComment.UpdateClubCommentUsecase do
  @moduledoc """
  Edits a club-post comment's body. Only the comment's own author may do
  this — enforced by the repository.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Club.UpdateClubComment.UpdateClubCommentUsecaseDto

  defstruct [:repository]

  def call(
        %UpdateClubCommentUsecaseDto{
          user: user,
          club_post_id: club_post_id,
          comment_id: comment_id,
          attrs: attrs
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.update_comment(user, club_post_id, comment_id, attrs, adaptee)
  end
end
