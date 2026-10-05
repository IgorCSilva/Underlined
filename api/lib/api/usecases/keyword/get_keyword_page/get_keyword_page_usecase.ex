defmodule Api.Usecases.Keyword.GetKeywordPage.GetKeywordPageUsecase do
  @moduledoc """
  A keyword's stats (posts/books/readers), related keywords, and a page of
  its posts, newest first.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Keyword.GetKeywordPage.GetKeywordPageUsecaseDto

  defstruct [:repository]

  def call(
        %GetKeywordPageUsecaseDto{name: name, before: before, current_user: current_user},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.get_keyword_page(name, before, current_user, adaptee)
  end
end
