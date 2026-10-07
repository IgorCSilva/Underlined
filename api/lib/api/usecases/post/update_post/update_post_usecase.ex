defmodule Api.Usecases.Post.UpdatePost.UpdatePostUsecase do
  @moduledoc """
  Edits a post's passage text and thinking. Only the post's author may
  edit it.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Post.UpdatePost.UpdatePostUsecaseDto

  defstruct [:repository]

  def call(
        %UpdatePostUsecaseDto{user: %User{} = user, post_id: post_id, attrs: attrs},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.update_post(user, post_id, attrs, adaptee)
  end
end
