defmodule Api.Usecases.Comment.UpdateComment.UpdateCommentUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Comment.UpdateComment.UpdateCommentUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :post_id, :comment_id, :attrs]
  defstruct [:user, :post_id, :comment_id, :attrs]

  @type t :: %__MODULE__{
          user: %User{},
          post_id: Ecto.UUID.t(),
          comment_id: Ecto.UUID.t(),
          attrs: map()
        }
end
