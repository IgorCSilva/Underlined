defmodule Api.Usecases.Post.CreatePost.CreatePostUsecase do
  @moduledoc """
  Publishes a passage + takeaway + keywords tied to a book.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Post.CreatePost.CreatePostUsecaseDto

  defstruct [:repository]

  def call(%CreatePostUsecaseDto{user: %User{} = user, attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.create_post(user, attrs, adaptee)
  end
end
