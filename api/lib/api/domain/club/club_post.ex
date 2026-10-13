defmodule Api.Domain.ClubPost do
  @moduledoc """
  Pure business-rule entity for one message in a club's discussion, in
  Step 18's chapter-scoped sense — unlike `Api.Domain.Post`, a club post
  carries no book passage or keywords of its own; it only ever belongs to
  a club and, optionally, one of that club's chapters. Holds no knowledge
  of Ecto, Postgres, or any other persistence detail.
  """

  defstruct [:id, :body, :chapter, :user, :comment_count, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: String.t(),
          body: String.t(),
          chapter: Api.Domain.ClubChapter.t() | nil,
          user: Api.Domain.User.t(),
          comment_count: non_neg_integer(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
