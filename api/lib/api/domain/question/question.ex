defmodule Api.Domain.Question do
  @moduledoc """
  Pure business-rule question entity. Holds no knowledge of Ecto, Postgres,
  or any other persistence detail.
  """

  defstruct [
    :id,
    :body,
    :answer_count,
    :book,
    :passage,
    :user,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          body: String.t(),
          answer_count: integer(),
          book: Api.Domain.Book.t(),
          passage: Api.Domain.Passage.t(),
          user: Api.Domain.User.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
