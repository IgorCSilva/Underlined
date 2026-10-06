defmodule ApiWeb.BookmarkJSON do
  alias ApiWeb.PostJSON

  def show(%{bookmark: bookmark}), do: %{data: bookmark}
  def index(%{posts: posts}), do: %{data: Enum.map(posts, &PostJSON.data/1)}
end
