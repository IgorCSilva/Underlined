defmodule Api.Usecases.UserBook.ListUserBooks.ListUserBooksUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.UserBook.ListUserBooks.ListUserBooksUsecase`.
  """

  @enforce_keys [:user_id]
  defstruct [:user_id]

  @type t :: %__MODULE__{user_id: Ecto.UUID.t()}
end
