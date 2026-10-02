defmodule Api.Usecases.Book.GetBook.GetBookUsecase do
  @moduledoc """
  Looks up a book by id, returning `nil` if the id is missing or malformed.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Book.GetBook.GetBookUsecaseDto

  defstruct [:repository]

  def call(%GetBookUsecaseDto{id: id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_book(id, adaptee)
  end
end
