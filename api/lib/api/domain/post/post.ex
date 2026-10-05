defmodule Api.Domain.Post do
  @moduledoc """
  Pure business-rule post entity. Holds no knowledge of Ecto, Postgres, or
  any other persistence detail.
  """

  defstruct [
    :id,
    :thinking,
    :like_count,
    :liked_by_user,
    :bookmarked_by_user,
    :comment_count,
    :book,
    :passage,
    :keywords,
    :user,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          thinking: String.t(),
          like_count: integer(),
          liked_by_user: boolean(),
          bookmarked_by_user: boolean(),
          comment_count: integer(),
          book: Api.Domain.Book.t(),
          passage: Api.Domain.Passage.t(),
          keywords: [Api.Domain.Keyword.t()],
          user: Api.Domain.User.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
