defmodule ApiWeb.KeywordJSON do
  alias ApiWeb.PostJSON

  def show(%{page: page}) do
    %{
      data: %{
        name: page.keyword.name,
        stats: page.stats,
        related_keywords: Enum.map(page.related_keywords, & &1.name),
        posts: Enum.map(page.posts, &PostJSON.data/1)
      }
    }
  end
end
