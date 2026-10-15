defmodule Api.Domain.Comment do
  @moduledoc """
  Pure business-rule comment entity. Holds no knowledge of Ecto, Postgres,
  or any other persistence detail.
  """

  defstruct [
    :id,
    :type,
    :body,
    :side,
    :parent_comment_id,
    :user,
    :replies,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          body: String.t(),
          side: String.t() | nil,
          parent_comment_id: String.t() | nil,
          user: Api.Domain.User.t(),
          replies: [t()],
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
