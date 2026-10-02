defmodule Api.Domain.UserToken do
  @moduledoc """
  Pure business-rule user-token entity. Holds no knowledge of Ecto, Postgres,
  or any other persistence detail.
  """

  defstruct [:id, :token, :context, :sent_to, :user_id, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          token: binary(),
          context: String.t(),
          sent_to: String.t(),
          user_id: String.t(),
          inserted_at: DateTime.t() | nil
        }
end
