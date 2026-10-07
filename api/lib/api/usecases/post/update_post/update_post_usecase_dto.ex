defmodule Api.Usecases.Post.UpdatePost.UpdatePostUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Post.UpdatePost.UpdatePostUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :post_id, :attrs]
  defstruct [:user, :post_id, :attrs]

  @type t :: %__MODULE__{user: %User{}, post_id: Ecto.UUID.t(), attrs: map()}
end
