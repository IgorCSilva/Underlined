defmodule Api.Usecases.Post.ListFollowingPosts.ListFollowingPostsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Post.ListFollowingPosts.ListFollowingPostsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user]
  defstruct [:user, :before]

  @type t :: %__MODULE__{user: %User{}, before: String.t() | nil}
end
