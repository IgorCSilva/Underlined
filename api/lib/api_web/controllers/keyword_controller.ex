defmodule ApiWeb.KeywordController do
  use ApiWeb, :controller

  alias Api.Adapters.Keywords
  alias Api.Usecases.Keyword.GetKeywordPage.GetKeywordPageUsecaseDto

  action_fallback ApiWeb.FallbackController

  def show(conn, %{"name" => name} = params) do
    with {:ok, page} <-
           Keywords.get_keyword_page(%GetKeywordPageUsecaseDto{
             name: name,
             before: params["before"],
             current_user: current_user(conn)
           }) do
      render(conn, :show, page: page)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
