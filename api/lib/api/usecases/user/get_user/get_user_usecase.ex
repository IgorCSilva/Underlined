defmodule Api.Usecases.User.GetUser.GetUserUsecase do
  @moduledoc """
  Looks up a user by id, returning `nil` if the id is missing or malformed.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.User.GetUser.GetUserUsecaseDto

  defstruct [:repository]

  def call(%GetUserUsecaseDto{id: id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_user(id, adaptee)
  end
end
