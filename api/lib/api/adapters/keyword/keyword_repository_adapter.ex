defmodule Api.Adapters.Keyword.KeywordRepositoryAdapter do
  @moduledoc """
  Converts a Postgres keyword entity into the pure Api.Domain.Keyword
  business entity. No standalone usecases need a keyword repository today —
  this is reused by the Post adapter to convert a post's nested keywords.
  """

  alias Api.Domain.Keyword, as: DomainKeyword

  @doc "Converts a Postgres keyword entity into the pure domain entity."
  def to_domain(db_keyword) do
    %DomainKeyword{
      id: db_keyword.id,
      name: db_keyword.name,
      inserted_at: db_keyword.inserted_at,
      updated_at: db_keyword.updated_at
    }
  end
end
