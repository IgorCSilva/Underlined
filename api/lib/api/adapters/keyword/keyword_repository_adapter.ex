defmodule Api.Adapters.Keyword.KeywordRepositoryAdapter do
  @moduledoc """
  Converts a Postgres keyword entity into the pure Api.Domain.Keyword
  business entity. Reused by the Post adapter to convert a post's nested
  keywords, and by the keyword-page usecase below.
  """

  alias Api.Adapters.Post.PostRepositoryAdapter
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

  @doc """
  Fetches the keyword page (keyword, stats, related keywords, posts) and
  converts every nested entity into its pure domain form.
  """
  def get_keyword_page(name, before, current_user, adaptee) do
    case adaptee.get_keyword_page(name, before, current_user) do
      {:error, :not_found} ->
        {:error, :not_found}

      {:ok, %{keyword: keyword, stats: stats, related: related, posts: posts}} ->
        {:ok,
         %{
           keyword: to_domain(keyword),
           stats: stats,
           related_keywords: Enum.map(related, &to_domain/1),
           posts: Enum.map(posts, &PostRepositoryAdapter.to_domain/1)
         }}
    end
  end
end
