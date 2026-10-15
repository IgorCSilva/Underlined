defmodule Api.Domain.Book do
  @moduledoc """
  Pure business-rule book entity. Holds no knowledge of Ecto, Postgres, or
  any other persistence detail.
  """

  defstruct [
    :id,
    :title,
    :author,
    :cover_url,
    :series_name,
    :series_position,
    :inserted_at,
    :updated_at,
    genres: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          author: String.t(),
          cover_url: String.t() | nil,
          genres: [String.t()],
          series_name: String.t() | nil,
          series_position: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
