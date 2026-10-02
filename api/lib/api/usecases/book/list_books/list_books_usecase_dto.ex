defmodule Api.Usecases.Book.ListBooks.ListBooksUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Book.ListBooks.ListBooksUsecase`.
  """

  defstruct [:query]

  @type t :: %__MODULE__{query: String.t() | nil}
end
