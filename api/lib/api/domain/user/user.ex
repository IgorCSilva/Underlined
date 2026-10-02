defmodule Api.Domain.User do
  @moduledoc """
  Pure business-rule user entity. Holds no knowledge of Ecto, Postgres, or
  any other persistence detail.
  """

  defstruct [
    :id,
    :email,
    :hashed_password,
    :name,
    :bio,
    :avatar_url,
    :confirmed_at,
    :enabled,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          email: String.t(),
          hashed_password: String.t() | nil,
          name: String.t(),
          bio: String.t() | nil,
          avatar_url: String.t() | nil,
          confirmed_at: DateTime.t() | nil,
          enabled: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
