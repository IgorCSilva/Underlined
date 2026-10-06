defmodule Api.Usecases.Bookmark.ListBookmarkedPosts.ListBookmarkedPostsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Bookmark.ListBookmarkedPosts.ListBookmarkedPostsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user]
  defstruct [:user, :before]

  @type t :: %__MODULE__{user: %User{}, before: String.t() | nil}
end
