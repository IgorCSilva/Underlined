defmodule Api.Usecases.Post.CreatePost.CreatePostUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Post.CreatePost.CreatePostUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :attrs]
  defstruct [:user, :attrs]

  @type t :: %__MODULE__{user: %User{}, attrs: map()}
end
