defmodule ApiWeb.DebateController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.Debate.GetDebate.GetDebateUsecaseDto

  action_fallback ApiWeb.FallbackController

  def show(conn, %{"id" => id}) do
    with {:ok, debate} <- Posts.get_debate(%GetDebateUsecaseDto{id: id}) do
      render(conn, :show, debate: debate)
    end
  end
end
