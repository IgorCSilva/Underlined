defmodule ApiWeb.LikeJSON do
  def show(%{like: like}), do: %{data: like}
end
