defmodule Api.Usecases.Book.AddBook.AddBookUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Book.AddBook.AddBookUsecase`.
  """

  @enforce_keys [:attrs]
  defstruct [:attrs]

  @type t :: %__MODULE__{attrs: map()}
end
