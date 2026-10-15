defmodule Api.Usecases.Post.SearchPosts.SearchPostsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Post.SearchPosts.SearchPostsUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:search]
  defstruct [:search, :current_user]

  @type t :: %__MODULE__{search: String.t(), current_user: User.t() | nil}
end
