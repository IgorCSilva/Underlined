defmodule Api.Usecases.Book.ListBooks.ListBooksUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Book.ListBooks.ListBooksUsecase`.
  """

  defstruct [:query, :series]

  @type t :: %__MODULE__{query: String.t() | nil, series: String.t() | nil}
end
