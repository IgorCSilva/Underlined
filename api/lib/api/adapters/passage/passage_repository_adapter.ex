defmodule Api.Adapters.Passage.PassageRepositoryAdapter do
  @moduledoc """
  Converts a Postgres passage entity into the pure Api.Domain.Passage
  business entity. No standalone usecases need a passage repository today —
  this is reused by the Post adapter to convert a post's nested passage.
  """

  alias Api.Domain.Passage, as: DomainPassage

  @doc "Converts a Postgres passage entity into the pure domain entity."
  def to_domain(db_passage) do
    %DomainPassage{
      id: db_passage.id,
      text: db_passage.text,
      book_id: db_passage.book_id,
      user_id: db_passage.user_id,
      inserted_at: db_passage.inserted_at,
      updated_at: db_passage.updated_at
    }
  end
end
