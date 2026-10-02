defmodule Api.Usecases.Post.ListPosts.ListPostsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Post.ListPosts.ListPostsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  defstruct [:before, :current_user]

  @type t :: %__MODULE__{before: String.t() | nil, current_user: %User{} | nil}
end
