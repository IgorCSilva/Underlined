defmodule Api.Usecases.Book.GetBookPage.GetBookPageUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Book.GetBookPage.GetBookPageUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:id]
  defstruct [:id, :before, :current_user]

  @type t :: %__MODULE__{
          id: String.t(),
          before: String.t() | nil,
          current_user: %User{} | nil
        }
end
