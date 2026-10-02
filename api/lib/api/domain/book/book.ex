defmodule Api.Domain.Book do
  @moduledoc """
  Pure business-rule book entity. Holds no knowledge of Ecto, Postgres, or
  any other persistence detail.
  """

  defstruct [:id, :title, :author, :cover_url, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          author: String.t(),
          cover_url: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
