defmodule Api.Usecases.Bookmark.BookmarkPost.BookmarkPostUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Bookmark.BookmarkPost.BookmarkPostUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :post_id]
  defstruct [:user, :post_id]

  @type t :: %__MODULE__{user: %User{}, post_id: Ecto.UUID.t()}
end
