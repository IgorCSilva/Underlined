defmodule ApiWeb.ClubPostJSON do
  alias Api.Domain.ClubPost
  alias ApiWeb.ClubChapterJSON

  def index(%{posts: posts}), do: %{data: Enum.map(posts, &data/1)}
  def show(%{post: post}), do: %{data: data(post)}

  def data(%ClubPost{} = post) do
    %{
      id: post.id,
      body: post.body,
      chapter: post.chapter && ClubChapterJSON.data(post.chapter),
      comment_count: post.comment_count,
      spoiler_blocked: post.spoiler_blocked,
      inserted_at: post.inserted_at,
      updated_at: post.updated_at,
      user: %{
        id: post.user.id,
        name: post.user.name,
        avatar_url: post.user.avatar_url
      }
    }
  end
end
