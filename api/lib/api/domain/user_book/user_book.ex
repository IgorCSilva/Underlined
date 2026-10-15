defmodule Api.Domain.UserBook do
  @moduledoc """
  Pure business-rule entity for one user's shelving of one book onto
  their personal bookcase: which of the three reading statuses it's on.
  Holds no knowledge of Ecto, Postgres, or any other persistence detail.
  """

  defstruct [:id, :status, :book, :inserted_at, :updated_at]

  @type status :: String.t()
  @type t :: %__MODULE__{
          id: String.t(),
          status: status(),
          book: Api.Domain.Book.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
