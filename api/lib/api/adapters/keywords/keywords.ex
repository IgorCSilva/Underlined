defmodule Api.Adapters.Keywords do
  @moduledoc """
  Facade over the keyword-page usecase.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Keyword.GetKeywordPage.GetKeywordPageUsecase

  def get_keyword_page(dto) do
    GetKeywordPageUsecase.call(dto, %GetKeywordPageUsecase{repository: keyword_repository()})
  end

  defp keyword_repository, do: Application.get_env(:api, :keyword_repository) |> Map.new()
end
