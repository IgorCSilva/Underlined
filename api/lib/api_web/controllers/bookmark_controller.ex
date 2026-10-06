defmodule ApiWeb.BookmarkController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.Bookmark.BookmarkPost.BookmarkPostUsecaseDto
  alias Api.Usecases.Bookmark.ListBookmarkedPosts.ListBookmarkedPostsUsecaseDto
  alias Api.Usecases.Bookmark.UnbookmarkPost.UnbookmarkPostUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, params) do
    posts =
      Posts.list_bookmarked_posts(%ListBookmarkedPostsUsecaseDto{
        user: current_user(conn),
        before: params["before"]
      })

    render(conn, :index, posts: posts)
  end

  def create(conn, %{"post_id" => post_id}) do
    with {:ok, bookmark} <-
           Posts.bookmark_post(%BookmarkPostUsecaseDto{
             user: current_user(conn),
             post_id: post_id
           }) do
      render(conn, :show, bookmark: bookmark)
    end
  end

  def delete(conn, %{"post_id" => post_id}) do
    with {:ok, bookmark} <-
           Posts.unbookmark_post(%UnbookmarkPostUsecaseDto{
             user: current_user(conn),
             post_id: post_id
           }) do
      render(conn, :show, bookmark: bookmark)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
