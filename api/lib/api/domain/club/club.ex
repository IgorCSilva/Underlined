defmodule Api.Domain.Club do
  @moduledoc """
  Pure business-rule book-club entity. Holds no knowledge of Ecto,
  Postgres, or any other persistence detail.
  """

  defstruct [
    :id,
    :name,
    :description,
    :book,
    :creator,
    :member_count,
    :members_preview,
    :joined_by_user,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          book: Api.Domain.Book.t(),
          creator: Api.Domain.User.t(),
          member_count: non_neg_integer(),
          members_preview: [Api.Domain.User.t()],
          joined_by_user: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
