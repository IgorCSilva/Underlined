defmodule Api.Domain.RefreshToken do
  @moduledoc """
  Pure business-rule refresh-token entity. Holds no knowledge of Ecto,
  Postgres, or any other persistence detail.
  """

  defstruct [:id, :token_hash, :expires_at, :remember_me, :user_id, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          token_hash: String.t(),
          expires_at: DateTime.t(),
          remember_me: boolean(),
          user_id: String.t(),
          inserted_at: DateTime.t() | nil
        }
end
