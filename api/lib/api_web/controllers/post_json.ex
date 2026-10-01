defmodule ApiWeb.PostJSON do
  alias Api.Posts.Post

  def index(%{posts: posts}), do: %{data: Enum.map(posts, &data/1)}
  def show(%{post: post}), do: %{data: data(post)}

  def data(%Post{} = post) do
    %{
      id: post.id,
      thinking: post.thinking,
      inserted_at: post.inserted_at,
      book: %{
        id: post.book.id,
        title: post.book.title,
        author: post.book.author,
        cover_url: post.book.cover_url
      },
      passage: %{
        id: post.passage.id,
        text: post.passage.text
      },
      keywords: Enum.map(post.keywords, & &1.name),
      user: %{
        id: post.user.id,
        name: post.user.name,
        avatar_url: post.user.avatar_url
      }
    }
  end
end
