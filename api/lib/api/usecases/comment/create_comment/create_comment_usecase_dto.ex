defmodule Api.Usecases.Comment.CreateComment.CreateCommentUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Comment.CreateComment.CreateCommentUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :post_id, :attrs]
  defstruct [:user, :post_id, :attrs]

  @type t :: %__MODULE__{user: %User{}, post_id: Ecto.UUID.t(), attrs: map()}
end
