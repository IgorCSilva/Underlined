defmodule Api.Usecases.Book.ListBooks.ListBooksUsecase do
  @moduledoc """
  Searches the book catalog, or lists the most recent books when no query is
  given.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Book.ListBooks.ListBooksUsecaseDto

  defstruct [:repository]

  def call(%ListBooksUsecaseDto{query: query}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_books(query, adaptee)
  end
end
