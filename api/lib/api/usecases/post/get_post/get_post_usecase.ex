defmodule Api.Usecases.Post.GetPost.GetPostUsecase do
  @moduledoc """
  Looks up a post by id, annotated with whether `current_user` liked it.
  Returns `nil` if the id is missing or malformed.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Post.GetPost.GetPostUsecaseDto

  defstruct [:repository]

  def call(%GetPostUsecaseDto{id: id, current_user: current_user}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_post(id, current_user, adaptee)
  end
end
