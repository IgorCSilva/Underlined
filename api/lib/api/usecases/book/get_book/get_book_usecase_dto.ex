defmodule Api.Usecases.Book.GetBook.GetBookUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Book.GetBook.GetBookUsecase`.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: Ecto.UUID.t()}
end
