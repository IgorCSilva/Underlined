defmodule Api.Domain.Passage do
  @moduledoc """
  Pure business-rule passage entity. Holds no knowledge of Ecto, Postgres,
  or any other persistence detail.
  """

  defstruct [:id, :text, :book_id, :user_id, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: String.t(),
          text: String.t(),
          book_id: String.t(),
          user_id: String.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
