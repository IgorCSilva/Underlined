defmodule Api.Usecases.Club.UpdateClubComment.UpdateClubCommentUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.UpdateClubComment.UpdateClubCommentUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :club_post_id, :comment_id, :attrs]
  defstruct [:user, :club_post_id, :comment_id, :attrs]

  @type t :: %__MODULE__{
          user: User.t(),
          club_post_id: Ecto.UUID.t(),
          comment_id: Ecto.UUID.t(),
          attrs: map()
        }
end
