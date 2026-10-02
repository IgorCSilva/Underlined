defmodule Api.Domain.Keyword do
  @moduledoc """
  Pure business-rule keyword entity. Holds no knowledge of Ecto, Postgres,
  or any other persistence detail.
  """

  defstruct [:id, :name, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
