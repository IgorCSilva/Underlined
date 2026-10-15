defmodule Api.Usecases.UserBook.SetUserBookStatus.SetUserBookStatusUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.UserBook.SetUserBookStatus.SetUserBookStatusUsecase`.
  """

  @enforce_keys [:user, :book_id, :status]
  defstruct [:user, :book_id, :status]

  @type t :: %__MODULE__{
          user: Api.Domain.User.t(),
          book_id: Ecto.UUID.t(),
          status: String.t()
        }
end
