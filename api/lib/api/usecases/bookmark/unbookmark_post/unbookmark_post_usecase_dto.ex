defmodule Api.Usecases.Bookmark.UnbookmarkPost.UnbookmarkPostUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Bookmark.UnbookmarkPost.UnbookmarkPostUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :post_id]
  defstruct [:user, :post_id]

  @type t :: %__MODULE__{user: %User{}, post_id: Ecto.UUID.t()}
end
