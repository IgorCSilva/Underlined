defmodule Api.Usecases.Book.AddBook.AddBookUsecase do
  @moduledoc """
  Adds a book, or returns the existing one if a book with the same
  title/author (case-insensitive) already exists.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto

  defstruct [:repository]

  def call(%AddBookUsecaseDto{attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.add_book(attrs, adaptee)
  end
end
