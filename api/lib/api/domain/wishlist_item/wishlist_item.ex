defmodule Api.Domain.WishlistItem do
  @moduledoc """
  Pure business-rule entity for one user wanting one book — presence
  only, no shelf status. Holds no knowledge of Ecto, Postgres, or any
  other persistence detail.
  """

  defstruct [:id, :book, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: String.t(),
          book: Api.Domain.Book.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
