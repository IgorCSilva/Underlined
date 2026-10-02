defmodule Api.Domain.Like do
  @moduledoc """
  Pure business-rule like entity. Holds no knowledge of Ecto, Postgres, or
  any other persistence detail.
  """

  defstruct [:id, :user_id, :post_id, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          user_id: String.t(),
          post_id: String.t(),
          inserted_at: DateTime.t() | nil
        }
end
