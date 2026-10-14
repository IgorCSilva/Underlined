defmodule Api.Domain.Chain do
  @moduledoc """
  Pure business-rule entity for a named, ordered sequence of posts. Holds
  no knowledge of Ecto, Postgres, or any other persistence detail.
  """

  defstruct [:id, :title, :user, :items, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          user: Api.Domain.User.t(),
          items: [Api.Domain.ChainItem.t()],
          inserted_at: DateTime.t() | nil
        }
end
